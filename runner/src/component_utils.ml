open Bos
open Dkml_install_register
open Dkml_install_api
open Error_handling.Monad_syntax

type static_files_source = Opam_context_static | Static_files_dir of string

(* Check all components to see if _any_ needs admin *)

let staging_files_source ~opam_context ~staging_files_opt =
  match (opam_context, staging_files_opt) with
  | false, None ->
      raise
        (Dkml_install_api.Installation_error
           "Either `--opam-context` or `--staging-files DIR` must be specified")
  | true, _ -> Path_eval.Opam_context
  | false, Some staging_files -> Staging_files_dir staging_files

let create_minimal_context ~self_component_name ~log_config ~prefix
    ~staging_files_source =
  let open Path_eval in
  let interpreter =
    Interpreter.create_minimal ~self_component_name ~staging_files_source
      ~prefix
  in
  let host_abi_v2 =
    match Host_abi.create_v2 () with
    | Ok abi -> abi
    | Error s ->
        raise
          (Dkml_install_api.Installation_error
             (Fmt.str "Could not detect the host ABI. %s" s))
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
    Component_registry.eval reg ~selector ~f:(fun cfg ->
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
    Component_registry.eval reg ~selector ~f:(fun cfg ->
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

(** [absdir_static_files ~component_name static_files_source] is
        the [component_name] component's static-files directory *)
let absdir_static_files ~component_name = function
  | Opam_context_static ->
      Os_utils.absdir_install_files ~component_name Static Opam_context
  | Static_files_dir static_files ->
      Os_utils.absdir_install_files ~component_name Static
        (Install_files_dir static_files)

let z s = "--" ^ s

let common_runner_args ~log_config ~prefix ~staging_files_source =
  let open Os_utils in
  let args =
    Cmd.(
      Log_config.to_args log_config
      % z Cmdliner_common.prefix_arg
      % normalize_path prefix)
  in
  let args =
    match staging_files_source with
    | Path_eval.Opam_context -> Cmd.(args % z Cmdliner_common.opam_context_args)
    | Staging_files_dir staging_files ->
        Cmd.(
          args
          % z Cmdliner_common.staging_files_arg
          % normalize_path staging_files)
  in
  args

let spawn cmd =
  Logs.info (fun m -> m "Running: %a" Cmd.pp cmd);
  Rresult.R.kignore_error ~use:(fun e ->
      let msg =
        Fmt.str "@[Failed to run:@,@[%s@]@]@,@[%a@]" (Cmd.to_string cmd)
          Rresult.R.pp_msg e
      in
      if Error_handling.errors_are_immediate () then
        raise (Dkml_install_api.Installation_error msg)
      else Result.error msg)
  @@ (OS.Cmd.(run_status cmd) >>= function
      | `Exited 0 -> Result.ok ()
      | `Exited v ->
          Rresult.R.error_msgf "Exited with exit code %d: %a" v Cmd.pp cmd
      | `Signaled v ->
          Rresult.R.error_msgf "Signaled with signal %d: %a" v Cmd.pp cmd)

let elevated_cmd cmd =
  if Sys.win32 then
    (* dkml-install-admin.exe on Win32 has a UAC manifest injected
       by link.exe in dune. But still will get
       "The requested operation requires elevation" if dkml-install-admin.exe
       is spawned from another process rather than directly from
       Command Prompt or PowerShell.
       So use `start` *)
    Cmd.(v "start" % "/wait" %% cmd)
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
