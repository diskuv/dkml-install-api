open Cmdliner
open Bos

let generate_installer_from_archive_dir ~archive_dir ~work_dir ~abi_selector
    ~organization ~program_name ~program_version ~target_dir =
  (* For Windows create a self-extracting executable.

     Since 7zr.exe is used to create a .7z archive, we can only run this on
     Windows today.

     See CROSSPLATFORM-TODO.md *)
  (if Sys.win32 then
   match abi_selector with
   | Dkml_install_runner.Path_location.Abi abi
     when Dkml_install_api.Context.Abi_v2.is_windows abi ->
       Installer_sfx.generate ~archive_dir ~target_dir ~abi_selector
         ~organization ~program_name ~program_version ~work_dir
   | _ -> ());
  (* All operating systems can have an archive *)
  Installer_archive.generate ~archive_dir ~target_dir ~abi_selector
    ~program_name ~program_version

let create_forone_abi ~abi_selector ~all_component_names ~organization
    ~program_name ~program_version ~opam_context ~work_dir ~target_dir
    ~runner_admin_exe ~runner_user_exe ~packager_entry_exe
    ~packager_setup_bytecode ~packager_uninstaller_bytecode =
  (* Create a temporary archive directory where we'll build the installer.contents
     For the benefit of Windows and macOS we keep the directory name ("a") small. *)
  let abi = Dkml_install_runner.Path_location.show_abi_selector abi_selector in
  let archive_dir = Fpath.(work_dir / "a" / abi) in
  let archive_staging_dir =
    Dkml_install_runner.Cmdliner_runner.staging_default_dir_for_package
      ~archive_dir
  in
  let archive_static_dir =
    Dkml_install_runner.Cmdliner_runner.static_default_dir_for_package
      ~archive_dir
  in
  (* Copy non-component files into archive *)
  Populate_archive.populate_archive ~archive_dir ~runner_admin_exe
    ~runner_user_exe ~packager_entry_exe ~packager_setup_bytecode
    ~packager_uninstaller_bytecode;
  (* Get Opam sources *)
  let opam_staging_files_source =
    Dkml_install_runner.Path_location.staging_files_source
      ~staging_default:No_staging_default ~opam_context_opt:(Some opam_context)
      ~staging_files_opt:None
  in
  let opam_static_files_source =
    Dkml_install_runner.Path_location.static_files_source
      ~static_default:No_static_default ~opam_context_opt:(Some opam_context)
      ~static_files_opt:None
  in
  (* Get archive destinations.

     The destinations are nothing more than a *_files_source which
     allows us to use the same code and context paths that the end-user
     machine will use.
  *)
  let archive_staging_files_dest =
    Dkml_install_runner.Path_location.staging_files_source
      ~staging_default:No_staging_default ~opam_context_opt:None
      ~staging_files_opt:(Some (Fpath.to_string archive_staging_dir))
  in
  let archive_static_files_dest =
    Dkml_install_runner.Path_location.static_files_source
      ~static_default:No_static_default ~opam_context_opt:None
      ~static_files_opt:(Some (Fpath.to_string archive_static_dir))
  in
  (* Copy xx-console plus all components from Opam into archive *)
  List.iter
    (fun component_name ->
      Populate_archive.populate_archive_component ~component_name ~abi_selector
        ~opam_staging_files_source ~opam_static_files_source
        ~archive_staging_files_dest ~archive_static_files_dest)
    ([ Dkml_package_console_common.console_component_name ]
    @ all_component_names);
  (* Assemble for one ABI *)
  generate_installer_from_archive_dir ~archive_dir ~work_dir ~abi_selector
    ~organization ~program_name ~program_version ~target_dir

let create_forall_abi (_log_config : Dkml_install_api.Log_config.t) organization
    program_name program_version work_dir target_dir opam_context abis
    runner_admin_exe runner_user_exe packager_entry_exe packager_setup_bytecode
    packager_uninstaller_bytecode =
  (* Get component plugins; logging already setup *)
  let reg = Dkml_install_register.Component_registry.get () in
  (* Get component names *)
  let all_component_names_res =
    Dkml_install_register.Component_registry.eval reg ~selector:All_components
      ~f:(fun cfg ->
        let module Cfg = (val cfg : Dkml_install_api.Component_config) in
        Result.ok Cfg.component_name)
  in
  let all_component_names =
    match all_component_names_res with
    | Ok var_list -> var_list
    | Error err -> failwith err
  in
  Logs.info (fun l ->
      l "Installers will be created that include the components: %a"
        Fmt.(Dump.list string)
        all_component_names);
  (* Get all ABIs, include Generic *)
  let abi_selectors =
    [ Dkml_install_runner.Path_location.Generic ]
    @ List.map (fun v -> Dkml_install_runner.Path_location.Abi v) abis
  in
  Logs.info (fun l ->
      l "Installers will be created for the ABIs: %a"
        Fmt.(Dump.list Dkml_install_runner.Path_location.pp_abi_selector)
        abi_selectors);
  List.iter
    (fun abi_selector ->
      create_forone_abi ~abi_selector ~all_component_names ~organization
        ~program_name ~program_version ~opam_context
        ~work_dir:(Fpath.v work_dir) ~target_dir:(Fpath.v target_dir)
        ~runner_admin_exe:(Fpath.v runner_admin_exe)
        ~runner_user_exe:(Fpath.v runner_user_exe)
        ~packager_entry_exe:(Fpath.v packager_entry_exe)
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

let runner_admin_exe_t =
  let doc = "The runner_admin.exe" in
  Arg.(
    required
    & opt (some file) None
    & info [ "runner-admin-exe" ] ~docv:"EXE" ~doc)

let runner_user_exe_t =
  let doc = "The runner_user.exe" in
  Arg.(
    required
    & opt (some file) None
    & info [ "runner-user-exe" ] ~docv:"EXE" ~doc)

let entry_exe_t =
  let doc = "The setup.exe generated by a (Console, etc.) packager" in
  Arg.(
    required
    & opt (some file) None
    & info [ "packager-entry-exe" ] ~docv:"EXE" ~doc)

let setup_bytecode_t =
  let doc = "The setup.bc generated by a (Console, etc.) packager" in
  Arg.(
    required
    & opt (some file) None
    & info [ "packager-setup-bytecode" ] ~docv:"BYTECODE" ~doc)

let uninstaller_bytecode_t =
  let doc = "The uninstaller.bc generated by a (Console, etc.) packager" in
  Arg.(
    required
    & opt (some file) None
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
      (Manpage.escape "$OPAMROOT")
      (Manpage.escape
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

(** [create_installers] creates a Console installer for each ABI, and one
    Console installer .tar.gz for "generic".

    On Windows the installer is a self-extracting 7zip archive that
    automatically runs setup.exe.

    On Unix the installer is simply a .tar.gz archive.

    The generic .tar.gz "installer" is likely unusable since it will not have
    any ABI specific files.
*)
let create_installers organization program_name =
  let t =
    Term.(
      const create_forall_abi $ Dkml_install_runner.Cmdliner_runner.setup_log_t
      $ const organization $ const program_name $ program_version_t $ work_dir_t
      $ target_dir_t $ opam_context_t $ abis_t $ runner_admin_exe_t
      $ runner_user_exe_t $ entry_exe_t $ setup_bytecode_t
      $ uninstaller_bytecode_t)
  in
  Term.(eval (t, info ~version:"%%VERSION%%" "dkml-install-create-installers"))
