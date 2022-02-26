open Bos
open Dkml_install_register
open Dkml_install_api
open Error_handling
open Error_handling.Monad_syntax

type static_files_source = Opam_context_static | Static_files_dir of string

(* Check all components to see if _any_ needs admin *)
let needs_install_admin reg =
  let at_least_one_component_needs_admin =
    let* needs_install_admin =
      Component_registry.eval reg ~f:(fun cfg ->
          let module Cfg = (val cfg : Component_config) in
          Result.ok @@ Cfg.needs_install_admin ())
    in
    Result.ok (List.exists Fun.id needs_install_admin)
  in
  match at_least_one_component_needs_admin with
  | Ok v -> v
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

let common_runner_args
    ~log_config:{ Cmdliner_common.log_config_style_renderer; log_config_level }
    ~prefix ~staging_files_source =
  let open Os_utils in
  let color =
    match log_config_style_renderer with
    | None -> "auto"
    | Some `None -> "never"
    | Some `Ansi_tty -> "always"
  in
  let args =
    Cmd.(
      empty
      % ("--verbosity=" ^ Logs.level_to_string log_config_level)
      % ("--color=" ^ color)
      % z Cmdliner_common.prefix_arg
      % normalize_path prefix)
  in
  let args =
    match staging_files_source with
    | Path_eval.Global_context.Opam_context ->
        Cmd.(args % z Cmdliner_common.opam_context_args)
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
        raise (Error_handling.Installation_error msg)
      else Result.error msg)
  @@ (OS.Cmd.(run_status cmd) >>= function
      | `Exited 0 -> Result.ok ()
      | `Exited v ->
          Rresult.R.error_msgf "Exited with exit code %d: %a" v Cmd.pp cmd
      | `Signaled v ->
          Rresult.R.error_msgf "Signaled with signal %d: %a" v Cmd.pp cmd)

let elevated_cmd cmd =
  if Sys.win32 then
    (* dkml-install-admin-exe on Win32 has a UAC manifest injected
       by link.exe in dune *)
    cmd
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
