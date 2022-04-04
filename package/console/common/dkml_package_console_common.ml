open Bos
open Dkml_install_api

let host_abi_v2 () =
  match Dkml_install_runner.Host_abi.create_v2 () with
  | Ok abi -> abi
  | Error s ->
      raise (Installation_error (Fmt.str "Could not detect the host ABI. %s" s))

let create_minimal_context ~self_component_name ~log_config ~prefix
    ~staging_files_source =
  let open Dkml_install_runner.Path_eval in
  let host_abi_v2 = host_abi_v2 () in
  let interpreter =
    Interpreter.create_minimal ~self_component_name ~abi:host_abi_v2
      ~staging_files_source ~prefix
  in
  {
    Context.eval = Interpreter.eval interpreter;
    path_eval = Interpreter.path_eval interpreter;
    host_abi_v2;
    log_config;
  }

let needs_install_admin ~reg ~selector ~log_config ~prefix ~staging_files_source
    =
  match
    Dkml_install_register.Component_registry.eval reg ~selector ~f:(fun cfg ->
        let module Cfg = (val cfg : Component_config) in
        let ctx =
          create_minimal_context ~self_component_name:Cfg.component_name
            ~log_config ~prefix ~staging_files_source
        in
        Logs.debug (fun l ->
            l
              "Checking if we need to request administrator privileges for %s \
               ..."
              Cfg.component_name);
        let ret = Cfg.needs_install_admin ~ctx in
        Logs.debug (fun l ->
            l "Administrator required to install %s? %b" Cfg.component_name ret);
        Result.ok ret)
  with
  | Ok bools -> List.exists Fun.id bools
  | Error msg -> raise (Installation_error msg)

let needs_uninstall_admin ~reg ~selector ~log_config ~prefix
    ~staging_files_source =
  match
    Dkml_install_register.Component_registry.eval reg ~selector ~f:(fun cfg ->
        let module Cfg = (val cfg : Component_config) in
        let ctx =
          create_minimal_context ~self_component_name:Cfg.component_name
            ~log_config ~prefix ~staging_files_source
        in
        Logs.debug (fun l ->
            l
              "Checking if we need to request administrator privileges for %s \
               ..."
              Cfg.component_name);
        let ret = Cfg.needs_uninstall_admin ~ctx in
        Logs.debug (fun l ->
            l "Administrator required to uninstall %s? %b" Cfg.component_name
              ret);
        Result.ok ret)
  with
  | Ok bools -> List.exists Fun.id bools
  | Error msg -> raise (Installation_error msg)

let spawn cmd =
  let open Dkml_install_runner.Error_handling.Monad_syntax in
  Logs.info (fun m -> m "Running: %a" Cmd.pp cmd);
  Rresult.R.kignore_error ~use:(fun e ->
      let msg =
        Fmt.str "@[Failed to run:@,@[%s@]@]@,@[%a@]" (Cmd.to_string cmd)
          Rresult.R.pp_msg e
      in
      if Dkml_install_runner.Error_handling.errors_are_immediate () then
        raise (Installation_error msg)
      else Result.error msg)
  @@ (OS.Cmd.(run_status cmd) >>= function
      | `Exited 0 -> Result.ok ()
      | `Exited v ->
          Rresult.R.error_msgf "Exited with exit code %d: %a" v Cmd.pp cmd
      | `Signaled v ->
          Rresult.R.error_msgf "Signaled with signal %d: %a" v Cmd.pp cmd)

let elevated_cmd ~staging_files_source cmd =
  let host_abi_v2 = host_abi_v2 () in
  if Context.Abi_v2.is_windows host_abi_v2 then
    (* dkml-install-admin.exe on Win32 has a UAC manifest injected
       by link.exe in dune. But still will get
       "The requested operation requires elevation" if dkml-install-admin.exe
       is spawned from another process rather than directly from
       Command Prompt or PowerShell.
       So use `gsudo` from dkml-package-console. *)
    let component_dir =
      Dkml_install_runner.Path_location.absdir_staging_files
        ~package_selector:Package ~component_name:"console"
        ~abi_selector:(Abi host_abi_v2) staging_files_source
    in
    let gsudo = Fpath.(component_dir / "bin" / "gsudo.exe") in
    match Logs.level () with
    | Some Debug ->
        Cmd.(
          v (Fpath.to_string gsudo) % "--wait" % "--direct" % "--debug" %% cmd)
    | Some _ | None ->
        Cmd.(v (Fpath.to_string gsudo) % "--wait" % "--direct" %% cmd)
  else
    match OS.Cmd.find_tool (Cmd.v "doas") with
    | Ok (Some fpath) -> Cmd.(v (Fpath.to_string fpath) %% cmd)
    | Ok None | Error _ -> (
        match OS.Cmd.find_tool (Cmd.v "sudo") with
        | Ok (Some fpath) -> Cmd.(v (Fpath.to_string fpath) %% cmd)
        | Ok None | Error _ ->
            let su =
              match OS.Cmd.resolve (Cmd.v "su") with
              | Ok v -> v
              | Error e ->
                  raise
                    (Installation_error
                       (Fmt.str "@[Could not escalate to a superuser:@]@ @[%a@]"
                          Rresult.R.pp_msg e))
            in

            (* su -c "dkml-install-admin-runner ..." *)
            Cmd.(su % "-c" % to_string cmd))

let home_dir_fp () =
  let open Dkml_install_runner.Error_handling in
  let open Dkml_install_runner.Error_handling.Monad_syntax in
  let* home_str = map_rresult_error_to_string @@ OS.Env.req_var "HOME" in
  let* home_fp = map_rresult_error_to_string @@ Fpath.of_string home_str in
  (* ensure HOME is a pre-existing directory *)
  map_rresult_error_to_string @@ OS.Dir.must_exist home_fp

let get_default_user_installation_prefix_windows ~name_camel_case_nospaces =
  let open Dkml_install_runner.Error_handling in
  let open Dkml_install_runner.Error_handling.Monad_syntax in
  let* local_app_data_str =
    map_rresult_error_to_string @@ OS.Env.req_var "LOCALAPPDATA"
  in
  let* local_app_data_fp =
    map_rresult_error_to_string @@ Fpath.of_string local_app_data_str
  in
  (* ensure LOCALAPPDATA is a pre-existing directory *)
  let* local_app_data_fp =
    map_rresult_error_to_string @@ OS.Dir.must_exist local_app_data_fp
  in
  Result.ok Fpath.(local_app_data_fp / "Programs" / name_camel_case_nospaces)

let get_default_user_installation_prefix_darwin ~name_camel_case_nospaces =
  let open Dkml_install_runner.Error_handling.Monad_syntax in
  let* home_dir_fp = home_dir_fp () in
  Result.ok Fpath.(home_dir_fp / "Applications" / name_camel_case_nospaces)

let get_default_user_installation_prefix_linux ~name_kebab_lower_case =
  let open Dkml_install_runner.Error_handling in
  let open Dkml_install_runner.Error_handling.Monad_syntax in
  match OS.Env.var "XDG_DATA_HOME" with
  | Some xdg_data_home ->
      let* fp = map_rresult_error_to_string @@ Fpath.of_string xdg_data_home in
      Result.ok Fpath.(fp / name_kebab_lower_case)
  | None ->
      let* home_dir_fp = home_dir_fp () in
      Result.ok Fpath.(home_dir_fp / ".local" / "share" / name_kebab_lower_case)

type program_name = {
  name_full : string;
  name_camel_case_nospaces : string;
  name_kebab_lower_case : string;
}

let get_user_installation_prefix ~program_name ~prefix_opt =
  match prefix_opt with
  | Some prefix -> Fpath.v prefix
  | None ->
      let open Dkml_install_runner.Error_handling in
      let host_abi_v2 = host_abi_v2 () in
      (if Context.Abi_v2.is_windows host_abi_v2 then
       get_default_user_installation_prefix_windows
         ~name_camel_case_nospaces:program_name.name_camel_case_nospaces
      else if Context.Abi_v2.is_darwin host_abi_v2 then
        get_default_user_installation_prefix_darwin
          ~name_camel_case_nospaces:program_name.name_camel_case_nospaces
      else if Context.Abi_v2.is_linux host_abi_v2 then
        get_default_user_installation_prefix_linux
          ~name_kebab_lower_case:program_name.name_kebab_lower_case
      else
        Result.error
          (Fmt.str
             "[14420023] No rules defined for the default user installation \
              prefix of the ABI %a"
             Context.Abi_v2.pp host_abi_v2))
      |> get_ok_or_raise_string

(* Command Line Processing *)

type package_args = {
  log_config : Log_config.t;
  prefix_opt : string option;
  component_selector : string list;
  static_files_source : Dkml_install_runner.Path_location.static_files_source;
  staging_files_source : Dkml_install_runner.Path_location.staging_files_source;
}

let prefix_opt_t ~program_name =
  let doc =
    Fmt.str
      "$(docv) is the installation directory. If not set and $(b,--%s) is also \
       not set, then $(i,%s) will be used as the installation directory"
      Dkml_install_runner.Cmdliner_common.opam_context_args
      (Cmdliner.Manpage.escape
         (Fpath.to_string
            (get_user_installation_prefix ~program_name ~prefix_opt:None)))
  in
  Cmdliner.Arg.(
    value
    & opt (some string) None
    & info
        [ Dkml_install_runner.Cmdliner_common.prefix_arg ]
        ~docv:"PREFIX" ~doc)

let package_args_t ~program_name =
  let package_args log_config prefix_opt component_selector static_files_source
      staging_files_source =
    {
      log_config;
      prefix_opt;
      component_selector;
      static_files_source;
      staging_files_source;
    }
  in
  Cmdliner.Term.(
    const package_args $ Dkml_install_runner.Cmdliner_runner.setup_log_t
    $ prefix_opt_t ~program_name
    $ Dkml_install_runner.Cmdliner_runner.component_selector_t ~install:true
    $ Dkml_install_runner.Cmdliner_runner.static_files_source_for_package_t
    $ Dkml_install_runner.Cmdliner_runner.staging_files_source_for_package_t)
