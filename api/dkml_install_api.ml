open Bos
open Cmdliner
module Context = Types.Context
module Forward_progress = Forward_progress

module type Component_config = Dkml_install_api_intf.Component_config

module type Component_config_defaultable =
  Dkml_install_api_intf.Component_config_defaultable

let administrator =
  if Sys.win32 then "Administrator privileges" else "root permissions"

module Default_component_config = struct
  let depends_on = []

  let do_nothing_with_ctx_t _ctx = ()

  let sdocs = Manpage.s_common_options

  let install_user_subcommand ~component_name ~subcommand_name ~fl ~ctx_t =
    let doc =
      Fmt.str
        "Currently does nothing. Would install the component '%s' except the \
         parts, if any, that need %s"
        component_name administrator
    in
    let cmd =
      Term.
        (const do_nothing_with_ctx_t $ ctx_t, info subcommand_name ~sdocs ~doc)
    in
    Forward_progress.return (cmd, fl)

  let uninstall_user_subcommand ~component_name ~subcommand_name ~fl ~ctx_t =
    let doc =
      Fmt.str
        "Currently does nothing. Would uninstall the component '%s' except the \
         parts, if any, that need %s"
        component_name administrator
    in
    let cmd =
      Term.
        (const do_nothing_with_ctx_t $ ctx_t, info subcommand_name ~sdocs ~doc)
    in
    Forward_progress.return (cmd, fl)

  let needs_install_admin ~ctx:(_ : Context.t) = false

  let needs_uninstall_admin ~ctx:(_ : Context.t) = false

  let install_admin_subcommand ~component_name ~subcommand_name ~fl ~ctx_t =
    let doc =
      Fmt.str
        "Currently does nothing. Would install the parts of the component '%s' \
         that need %s"
        component_name administrator
    in
    let cmd =
      Term.
        (const do_nothing_with_ctx_t $ ctx_t, info subcommand_name ~sdocs ~doc)
    in
    Forward_progress.return (cmd, fl)

  let uninstall_admin_subcommand ~component_name ~subcommand_name ~fl ~ctx_t =
    let doc =
      Fmt.str
        "Currently does nothing. Would uninstall the parts of the component \
         '%s' that need %s"
        component_name administrator
    in
    let cmd =
      Term.
        (const do_nothing_with_ctx_t $ ctx_t, info subcommand_name ~sdocs ~doc)
    in
    Forward_progress.return (cmd, fl)

  let test () = ()
end

module Log_config = struct
  include Log_config
end

let log_spawn_onerror_exit ~id ?conformant_subprocess_exitcodes cmd =
  Logs.info (fun m -> m "Running command: %a" Cmd.pp cmd);
  let fl = Forward_progress.stderr_fatallog in
  let open Astring in
  let sequence =
    let ( let* ) = Result.bind in
    let* env = OS.Env.current () in
    let new_env =
      let is_not_defined =
        match String.Map.find "OCAMLRUNPARAM" env with
        | None -> true
        | Some "" -> true
        | Some _ -> false
      in
      if is_not_defined then String.Map.add "OCAMLRUNPARAM" "b" env else env
    in
    OS.Cmd.run_status ~env:new_env cmd
  in
  match sequence with
  | Ok (`Exited 0) ->
      Logs.info (fun m ->
          m "%a ran successfully" Fmt.(option string) (Cmd.line_tool cmd));
      ()
  | Ok (`Exited spawned_exitcode) ->
      let adjective, exitcode =
        if conformant_subprocess_exitcodes = Some false then
          ("", Forward_progress.Exit_code.Exit_transient_failure)
        else
          ( "conformant ",
            List.fold_left
              (fun acc ec ->
                if
                  spawned_exitcode
                  = Forward_progress.Exit_code.to_int_exitcode ec
                then ec
                else acc)
              Forward_progress.Exit_code.Exit_transient_failure
              Forward_progress.Exit_code.values )
      in
      fl ~id
        (Fmt.str "%s. Root cause: The %scommand %a exited with code %d"
           (Forward_progress.Exit_code.to_short_sentence exitcode)
           adjective Cmd.pp cmd spawned_exitcode);
      exit (Forward_progress.Exit_code.to_int_exitcode exitcode)
  | Ok (`Signaled c) ->
      fl ~id (Fmt.str "The command %a terminated from a signal %d" Cmd.pp cmd c);
      exit (Forward_progress.Exit_code.to_int_exitcode Exit_transient_failure)
  | Error rmsg ->
      fl ~id
        (Fmt.str "The command %a could not be run due to: %a" Cmd.pp cmd
           Rresult.R.pp_msg rmsg);
      exit (Forward_progress.Exit_code.to_int_exitcode Exit_transient_failure)
