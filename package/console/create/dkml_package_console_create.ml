open Bos
open Dkml_install_runner.Error_handling.Monad_syntax
module Arg = Cmdliner.Arg
module Term = Cmdliner.Term

let generate_installer_from_archive_dir ~install_direction ~archive_dir
    ~work_dir ~abi_selector ~organization ~program_name ~program_version
    ~target_dir =
  (* For Windows create a self-extracting executable.

     Since 7zr.exe is used to create a .7z archive, we can only run this on
     Windows today.

     See CROSSPLATFORM-TODO.md *)
  let uninstallers = ref None in
  (if Sys.win32 then
   match abi_selector with
   | Dkml_install_runner.Path_location.Abi abi
     when Dkml_install_api.Context.Abi_v2.is_windows abi ->
       let installer_path =
         Installer_sfx.generate ~install_direction ~archive_dir ~target_dir
           ~abi_selector ~organization ~program_name ~program_version ~work_dir
       in
       if
         install_direction
         = Dkml_install_runner.Path_eval.Global_context.Uninstall
       then uninstallers := Some installer_path
   | _ -> ());
  (* All operating systems can have an archive *)
  let* (), _fl =
    Installer_archive.generate ~install_direction ~archive_dir ~target_dir
      ~abi_selector ~program_name ~program_version
  in
  return !uninstallers

let create_forone_abi ~abi_selector ~install_component_names
    ~uninstall_component_names ~organization ~program_name ~program_version
    ~program_info ~opam_context ~work_dir ~target_dir ~runner_admin_exe
    ~runner_user_exe ~packager_install_exe ~packager_uninstall_exe
    ~packager_setup_bytecode ~packager_uninstaller_bytecode =
  let abi = Dkml_install_runner.Path_location.show_abi_selector abi_selector in
  (* Get Opam sources *)
  let* opam_staging_files_source, _fl =
    Dkml_install_runner.Path_location.staging_files_source
      ~staging_default:No_staging_default ~opam_context_opt:(Some opam_context)
      ~staging_files_opt:None
  in
  let* opam_static_files_source, _fl =
    Dkml_install_runner.Path_location.static_files_source
      ~static_default:No_static_default ~opam_context_opt:(Some opam_context)
      ~static_files_opt:None
  in
  let create_installer install_direction archive_dir component_names
      packager_entry_exe packager_bytecode =
    (* Create a temporary archive directory where we'll build the installer.contents
       For the benefit of Windows and macOS we keep the directory name ("a") small. *)
    let archive_staging_dir =
      Dkml_install_runner.Cmdliner_runner.staging_default_dir_for_package
        ~archive_dir
    in
    let archive_static_dir =
      Dkml_install_runner.Cmdliner_runner.static_default_dir_for_package
        ~archive_dir
    in
    (* Copy non-component files into archive *)
    Populate_archive.populate_archive ~archive_dir ~abi_selector
      ~runner_admin_exe ~runner_user_exe ~packager_entry_exe ~packager_bytecode;
    (* Get archive destinations.

       The destinations are nothing more than a *_files_source which
       allows us to use the same code and context paths that the end-user
       machine will use.
    *)
    let* archive_staging_files_dest, _fl =
      Dkml_install_runner.Path_location.staging_files_source
        ~staging_default:No_staging_default ~opam_context_opt:None
        ~staging_files_opt:(Some (Fpath.to_string archive_staging_dir))
    in
    let* archive_static_files_dest, _fl =
      Dkml_install_runner.Path_location.static_files_source
        ~static_default:No_static_default ~opam_context_opt:None
        ~static_files_opt:(Some (Fpath.to_string archive_static_dir))
    in
    (* Copy all components from Opam into archive *)
    List.iter
      (fun component_name ->
        Populate_archive.populate_archive_component ~component_name
          ~abi_selector ~opam_staging_files_source ~opam_static_files_source
          ~archive_staging_files_dest ~archive_static_files_dest)
      component_names;
    (* Assemble for one ABI. Return uninstaller, if any *)
    generate_installer_from_archive_dir ~install_direction ~archive_dir
      ~work_dir ~abi_selector ~organization ~program_name ~program_version
      ~target_dir
  in
  (* Separate install and uninstall components.

     The install direction will be placed in work/a/i/* and target/i-*.
     The uninstall direction will be placed in work/a/u/* and target/u-*.

     The target/ directory has by design no subdirectories (aka. it is _flat_)
     so that a single release directory can be made.
     A flat directory is necessary for GitHub Releases.

     Only the i- and u- prefixes distinguish installers from uninstallers. We
     didn't use "setup-" and "uninstall-" prefixes because those would conflict
     with the probable names of signed Windows executables (which belong to the
     same Releases namespace).

     The uninstaller is done first because it has to be bundled into
     the installer.
  *)
  let get_archive_dir direction_dir =
    Fpath.(work_dir / "a" / direction_dir / abi)
  in
  let install_archive_dir = get_archive_dir "i" in
  let uninstall_archive_dir = get_archive_dir "u" in
  let* uninstaller_opt, _fl =
    create_installer Dkml_install_runner.Path_eval.Global_context.Uninstall
      uninstall_archive_dir uninstall_component_names packager_uninstall_exe
      packager_uninstaller_bytecode
  in
  (match
     ( uninstaller_opt,
       abi_selector,
       program_info
         .Dkml_package_console_common.Author_types.embeds_32bit_uninstaller,
       program_info
         .Dkml_package_console_common.Author_types.embeds_64bit_uninstaller )
   with
  | Some uninstaller, Abi Windows_x86, true, _
  | Some uninstaller, Abi Windows_x86_64, _, true ->
      Populate_archive.copy_file ~src:uninstaller
        ~dst:Fpath.(install_archive_dir / "bin" / "dkml-package-uninstall.exe")
  | Some _, _, _, _ | None, _, _, _ -> ());
  let* _uninstallers, _fl =
    create_installer Dkml_install_runner.Path_eval.Global_context.Install
      install_archive_dir install_component_names packager_install_exe
      packager_setup_bytecode
  in
  return ()

let create_forall_abi (_log_config : Dkml_install_api.Log_config.t) organization
    program_name program_info program_version component_list work_dir target_dir
    opam_context abis runner_admin_exe runner_user_exe packager_install_exe
    packager_uninstall_exe packager_setup_bytecode packager_uninstaller_bytecode
    =
  (* Get component plugins; logging already setup *)
  let reg = Dkml_install_register.Component_registry.get () in
  (* Get component names.

     Install/uninstall may have different components because
     "install_depends_on" and "uninstall_depends_on" component values
     may be different.

     For example, an uninstaller for Windows may not need to bundle in MSYS2.
  *)
  let* install_component_names, _fl =
    Dkml_install_register.Component_registry.install_eval reg
      ~selector:(Just_named_components_plus_their_dependencies component_list)
      ~fl:Dkml_install_runner.Error_handling.runner_fatal_log ~f:(fun cfg ->
        let module Cfg = (val cfg : Dkml_install_api.Component_config) in
        return Cfg.component_name)
  in
  let* uninstall_component_names, _fl =
    Dkml_install_register.Component_registry.uninstall_eval reg
      ~selector:(Just_named_components_plus_their_dependencies component_list)
      ~fl:Dkml_install_runner.Error_handling.runner_fatal_log ~f:(fun cfg ->
        let module Cfg = (val cfg : Dkml_install_api.Component_config) in
        return Cfg.component_name)
  in
  (* IMPORTANT: We always add
     {!Dkml_package_console_common.console_required_components} for both
     installers and uninstallers
  *)
  let install_component_names =
    List.sort_uniq String.compare
      (Dkml_package_console_common.console_required_components
     @ install_component_names)
  in
  let uninstall_component_names =
    List.sort_uniq String.compare
      (Dkml_package_console_common.console_required_components
     @ uninstall_component_names)
  in
  Logs.info (fun l ->
      l "@[Installers will be created that include the components:@]@ @[<v>%a@]"
        Fmt.(Dump.list string)
        install_component_names);
  Logs.info (fun l ->
      l
        "@[Uninstallers will be created that include the components:@]@ \
         @[<v>%a@]"
        Fmt.(Dump.list string)
        uninstall_component_names);
  (* Get all ABIs, include Generic *)
  let abi_selectors =
    [ Dkml_install_runner.Path_location.Generic ]
    @ List.map (fun v -> Dkml_install_runner.Path_location.Abi v) abis
  in
  Logs.info (fun l ->
      l "Installers and uninstallers will be created for the ABIs:@ %a"
        Fmt.(Dump.list Dkml_install_runner.Path_location.pp_abi_selector)
        abi_selectors);
  Dkml_install_api.Forward_progress.iter
    ~fl:Dkml_install_runner.Error_handling.runner_fatal_log
    (fun abi_selector ->
      create_forone_abi ~abi_selector ~install_component_names
        ~uninstall_component_names ~organization ~program_name ~program_version
        ~program_info ~opam_context ~work_dir:(Fpath.v work_dir)
        ~target_dir:(Fpath.v target_dir)
        ~runner_admin_exe:(Fpath.v runner_admin_exe)
        ~runner_user_exe:(Fpath.v runner_user_exe)
        ~packager_install_exe:(Fpath.v packager_install_exe)
        ~packager_uninstall_exe:(Fpath.v packager_uninstall_exe)
        ~packager_setup_bytecode:(Fpath.v packager_setup_bytecode)
        ~packager_uninstaller_bytecode:(Fpath.v packager_uninstaller_bytecode))
    abi_selectors

let program_version_t =
  let doc = "The version of the program that will be installed" in
  Arg.(required & opt (some string) None & info [ "program-version" ] ~doc)

let abis_t =
  let open Dkml_install_api.Context.Abi_v2 in
  let l =
    List.map
      (fun v -> (to_canonical_string v, v))
      Dkml_install_api.Context.Abi_v2.values
  in
  let doc =
    "An ABI to build an installer for. Defaults to all of the supported ABIs"
  in
  Arg.(
    value
    & opt_all (enum l) Dkml_install_api.Context.Abi_v2.values
    & info [ "abi" ] ~doc ~docv:"ABI")

let work_dir_t =
  let doc =
    "A working directory for use generating the installer. It is your \
     responsibility to clean it up"
  in
  Arg.(required & opt (some dir) None & info [ "work-dir" ] ~docv:"DIR" ~doc)

let target_dir_t =
  let doc = "The directory to place the installer and any supporting files" in
  Arg.(required & opt (some dir) None & info [ "target-dir" ] ~docv:"DIR" ~doc)

let wildcard_doc =
  "Any $(dune-context) in the path will expand to either 'default.TARGET_ABI' \
   if it is present, or 'default' if it is not present. For example, if you \
   have done cross-compilation using opam-monorepo and `dune build -x \
   darwin_arm64`, then `_build/install/$(dune-context)/bin/a.exe` will expand \
   to `_build/install/default.darwin_arm64/bin/some.executable` if \
   some.executable exists, otherwise \
   `_build/install/default/bin/some.executable` is used as the path. With this \
   mechanism cross-compiled binaries can replace native binaries."

let runner_admin_exe_t =
  let doc = "The runner_admin.exe. " ^ wildcard_doc in
  Arg.(
    required
    & opt (some string) None
    & info [ "runner-admin-exe" ] ~docv:"EXE" ~doc)

let runner_user_exe_t =
  let doc = "The runner_user.exe. " ^ wildcard_doc in
  Arg.(
    required
    & opt (some string) None
    & info [ "runner-user-exe" ] ~docv:"EXE" ~doc)

let entry_install_exe_t =
  let doc =
    "The setup.exe generated by a (Console, etc.) packager. " ^ wildcard_doc
  in
  Arg.(
    required
    & opt (some string) None
    & info [ "packager-install-exe" ] ~docv:"EXE" ~doc)

let entry_uninstall_exe_t =
  let doc =
    "The uninstall.exe generated by a (Console, etc.) packager. " ^ wildcard_doc
  in
  Arg.(
    required
    & opt (some string) None
    & info [ "packager-uninstall-exe" ] ~docv:"EXE" ~doc)

let setup_bytecode_t =
  let doc =
    "The setup.bc generated by a (Console, etc.) packager. " ^ wildcard_doc
  in
  Arg.(
    required
    & opt (some string) None
    & info [ "packager-setup-bytecode" ] ~docv:"BYTECODE" ~doc)

let uninstaller_bytecode_t =
  let doc =
    "The uninstaller.bc generated by a (Console, etc.) packager. "
    ^ wildcard_doc
  in
  Arg.(
    required
    & opt (some string) None
    & info [ "packager-uninstaller-bytecode" ] ~docv:"BYTECODE" ~doc)

let opam_context_t =
  let doc =
    Fmt.str
      "Obtain staging files from an Opam switch. A switch prefix is either the \
       $(b,_opam) subdirectory of a local Opam switch or $(b,%s/<switchname>) \
       for a global Opam switch. $(opt) is required when there is no \
       OPAM_SWITCH_PREFIX environment variable; otherwise the value of \
       OPAM_SWITCH_PREFIX is the default for $(opt). The OPAM_SWITCH_PREFIX \
       environment variable is set automatically by commands like `%s`."
      (Cmdliner.Manpage.escape "$OPAMROOT")
      (Cmdliner.Manpage.escape
         "(& opam env) -split '\\r?\\n' | ForEach-Object { Invoke-Expression \
          $_ }` for Windows PowerShell or `eval $(opam env)")
  in
  let inf =
    Arg.info
      [ Dkml_install_runner.Cmdliner_common.opam_context_args ]
      ~docv:"OPAM_SWITCH_PREFIX" ~doc
  in
  let unbackslash = function '\\' -> '/' | c -> c in
  match OS.Env.var "OPAM_SWITCH_PREFIX" with
  | Some current_opam_switch_prefix ->
      Arg.(
        value
        & opt dir (String.map unbackslash current_opam_switch_prefix)
        & inf)
  | None -> Arg.(required & opt (some dir) None & inf)

let component_list_t =
  let doc =
    "A component to add to the installer and uninstaller. All the \
     [install_depends_on] components of the specified component are added as \
     well to the installer. Similarly all the [uninstall_depends_on] \
     components of the specified component are added as well to the \
     uninstaller. May be repeated. At least one component must be specified."
  in
  Arg.(non_empty & opt_all string [] & info [ "component" ] ~doc)

(** [create_installers] creates a Console installer for each ABI, and one
    Console installer .tar.gz for "generic".

    On Windows the installer is a self-extracting 7zip archive that
    automatically runs setup.exe.

    On Unix the installer is simply a .tar.gz archive.

    The generic .tar.gz "installer" is likely unusable since it will not have
    any ABI specific files.
*)
let create_installers organization program_name program_info =
  let t =
    Term.(
      const create_forall_abi $ Dkml_install_runner.Cmdliner_runner.setup_log_t
      $ const organization $ const program_name $ const program_info
      $ program_version_t $ component_list_t $ work_dir_t $ target_dir_t
      $ opam_context_t $ abis_t $ runner_admin_exe_t $ runner_user_exe_t
      $ entry_install_exe_t $ entry_uninstall_exe_t $ setup_bytecode_t
      $ uninstaller_bytecode_t)
  in
  Dkml_install_runner.Cmdliner_runner.eval_progress
    (t, Term.info ~version:"%%VERSION%%" "dkml-install-create-installers")
