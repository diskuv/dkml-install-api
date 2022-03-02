open Bos
open Cmdliner
module Context = Types.Context

module type Component_config = Dkml_install_api_intf.Component_config

module type Component_config_defaultable =
  Dkml_install_api_intf.Component_config_defaultable

let administrator =
  if Sys.win32 then "Administrator privileges" else "root permissions"

module Default_component_config = struct
  let depends_on = []

  let do_nothing_with_ctx_t _ctx = ()

  let sdocs = Manpage.s_common_options

  let install_user_subcommand ~component_name ~subcommand_name ~ctx_t =
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
    Result.ok cmd

  let uninstall_user_subcommand ~component_name ~subcommand_name ~ctx_t =
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
    Result.ok cmd

  let needs_install_admin () = false

  let needs_uninstall_admin () = false

  let install_admin_subcommand ~component_name ~subcommand_name ~ctx_t =
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
    Result.ok cmd

  let uninstall_admin_subcommand ~component_name ~subcommand_name ~ctx_t =
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
    Result.ok cmd

  let test () = ()
end

exception Installation_error of string

let log_spawn_and_raise cmd =
  Logs.info (fun m -> m "Running command: %a" Cmd.pp cmd);
  let ( let* ) = Result.bind in
  let open Astring in
  let sequence =
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
      Logs.info (fun m -> m "The command %a ran successfully" Cmd.pp cmd)
  | Ok (`Exited c) ->
      raise
        (Installation_error
           (Fmt.str "The command %a exited with status %d" Cmd.pp cmd c))
  | Ok (`Signaled c) ->
      raise
        (Installation_error
           (Fmt.str "The command %a terminated from a signal %d" Cmd.pp cmd c))
  | Error rmsg ->
      raise
        (Installation_error
           (Fmt.str "The command %a could not be run due to: %a" Cmd.pp cmd
              Rresult.R.pp_msg rmsg))
