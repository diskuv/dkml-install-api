open Bos

let host_abi_v2 () =
  match Runner.Host_abi.create_v2 () with
  | Ok abi -> abi
  | Error s ->
      raise
        (Dkml_install_api.Installation_error
           (Fmt.str "Could not detect the host ABI. %s" s))

let create_minimal_context ~self_component_name ~log_config ~prefix
    ~staging_files_source =
  let open Runner.Path_eval in
  let host_abi_v2 = host_abi_v2 () in
  let interpreter =
    Interpreter.create_minimal ~self_component_name ~abi:host_abi_v2
      ~staging_files_source ~prefix
  in
  {
    Dkml_install_api.Context.eval = Interpreter.eval interpreter;
    path_eval = Interpreter.path_eval interpreter;
    host_abi_v2;
    log_config;
  }

let needs_install_admin ~reg ~selector ~log_config ~prefix ~staging_files_source
    =
  match
    Dkml_install_register.Component_registry.eval reg ~selector ~f:(fun cfg ->
        let module Cfg = (val cfg : Dkml_install_api.Component_config) in
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
  | Error msg -> raise (Dkml_install_api.Installation_error msg)

let needs_uninstall_admin ~reg ~selector ~log_config ~prefix
    ~staging_files_source =
  match
    Dkml_install_register.Component_registry.eval reg ~selector ~f:(fun cfg ->
        let module Cfg = (val cfg : Dkml_install_api.Component_config) in
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
  | Error msg -> raise (Dkml_install_api.Installation_error msg)

let common_runner_args ~log_config ~prefix ~staging_files_source =
  let open Runner.Os_utils in
  let z s = "--" ^ s in
  let args =
    Cmd.(
      Dkml_install_api.Log_config.to_args log_config
      % z Runner.Cmdliner_common.prefix_arg
      % normalize_path prefix)
  in
  let args =
    match staging_files_source with
    | Runner.Path_location.Opam_context_staging ->
        Cmd.(args % z Runner.Cmdliner_common.opam_context_args)
    | Staging_files_dir staging_files ->
        Cmd.(
          args
          % z Runner.Cmdliner_common.staging_files_arg
          % normalize_path staging_files)
  in
  args

let spawn cmd =
  let open Runner.Error_handling.Monad_syntax in
  Logs.info (fun m -> m "Running: %a" Cmd.pp cmd);
  Rresult.R.kignore_error ~use:(fun e ->
      let msg =
        Fmt.str "@[Failed to run:@,@[%s@]@]@,@[%a@]" (Cmd.to_string cmd)
          Rresult.R.pp_msg e
      in
      if Runner.Error_handling.errors_are_immediate () then
        raise (Dkml_install_api.Installation_error msg)
      else Result.error msg)
  @@ (OS.Cmd.(run_status cmd) >>= function
      | `Exited 0 -> Result.ok ()
      | `Exited v ->
          Rresult.R.error_msgf "Exited with exit code %d: %a" v Cmd.pp cmd
      | `Signaled v ->
          Rresult.R.error_msgf "Signaled with signal %d: %a" v Cmd.pp cmd)

let elevated_cmd ~staging_files_source cmd =
  let host_abi_v2 = host_abi_v2 () in
  if Dkml_install_api.Context.Abi_v2.is_windows host_abi_v2 then
    (* dkml-install-admin.exe on Win32 has a UAC manifest injected
       by link.exe in dune. But still will get
       "The requested operation requires elevation" if dkml-install-admin.exe
       is spawned from another process rather than directly from
       Command Prompt or PowerShell.
       So use `gsudo` from dkml-package-textarchive. *)
    let component_dir =
      Runner.Path_location.absdir_staging_files ~package_selector:Package
        ~component_name:"textarchive" ~abi_selector:(Abi host_abi_v2)
        staging_files_source
    in
    let gsudo = Fpath.(v component_dir / "bin" / "gsudo.exe") in
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
                    (Dkml_install_api.Installation_error
                       (Fmt.str "@[Could not escalate to a superuser:@]@ @[%a@]"
                          Rresult.R.pp_msg e))
            in

            (* su -c "dkml-install-admin-runner ..." *)
            Cmd.(su % "-c" % to_string cmd))
