open Cmdliner
open Dkml_install_register
open Dkml_install_api

let ( >>= ) = Result.bind

let help man_format cmds topic =
  match topic with
  | None -> `Help (`Pager, None) (* help about the program. *)
  | Some topic -> (
      let topics = "topics" :: cmds in
      let conv, _ = Cmdliner.Arg.enum (List.rev_map (fun s -> (s, s)) topics) in
      match conv topic with
      | `Error e -> `Error (false, e)
      | `Ok t when t = "topics" ->
          List.iter print_endline topics;
          `Ok ()
      | `Ok t when List.mem t cmds -> `Help (man_format, Some t)
      | `Ok _t ->
          (* should never get here if all `topics` are handled *)
          `Help (`Pager, None))

(* Help sections common to all commands *)

let help_secs =
  [
    `S Manpage.s_common_options;
    `P "These options are common to all commands.";
    `S "MORE HELP";
    `P "Use $(mname) $(i,COMMAND) --help for help on a single command.";
  ]

(* Options common to all commands *)

let setup_log style_renderer level =
  Fmt_tty.setup_std_outputs ?style_renderer ();
  Logs.set_level level;
  Logs.set_reporter (Logs_fmt.reporter ());
  ()

let setup_log_t =
  Term.(const setup_log $ Fmt_cli.style_renderer () $ Logs_cli.level ())

(** [setup_t] is a [Term] that sets up logging and any other global state *)
let setup_t = setup_log_t

(* Commands *)

let help_cmd =
  let topic =
    let doc = "The topic to get help on. `topics' lists the topics." in
    Arg.(value & pos 0 (some string) None & info [] ~docv:"TOPIC" ~doc)
  in
  let doc =
    "display help about dkml-install-runner and dkml-install-runner commands"
  in
  let man =
    [
      `S Manpage.s_description;
      `P "Prints help about dkml-install-runner commands and other subjects...";
      `Blocks help_secs;
    ]
  in
  ( Term.(ret (const help $ Arg.man_format $ Term.choice_names $ topic)),
    Term.info "help" ~doc ~exits:Term.default_exits ~man )

let default_cmd =
  let doc = "the OCaml CLI installer" in
  let sdocs = Manpage.s_common_options in
  let exits = Term.default_exits in
  let man = help_secs in
  ( Term.(ret (const (fun () -> `Help (`Pager, None)) $ setup_t)),
    Term.info "dkml-install-runner" ~version:"%%VERSION%%" ~doc ~sdocs ~exits
      ~man )

let cmds = [ help_cmd ]

(* Load dkml-install-api module so that Dynlink access control
   does not prohibit plugins (components) from loading it by
   raising a Dynlink.Unavailable_unit error.

   Confer:
   https://ocaml.org/api/Dynlink.html#1_Accesscontrol "set_allowed_units" *)
let (_ : string list) = Default_component_config.depends_on

(* Load all the available components *)
let () = Sites.Plugins.Plugins.load_all ()

(* Install all CLI subcommands for all the components *)
let component_cmds =
  let reg = Component_registry.get () in
  let cmd_results =
    Component_registry.eval reg ~f:(fun cfg ->
        let module Cfg = (val cfg : Component_config) in
        Cfg.install_user_subcommand ~component_name:Cfg.component_name
          ~subcommand_name:(Fmt.str "install-user-%s" Cfg.component_name)
          ~setup_t)
    >>= fun install_user_cmds ->
    Component_registry.eval reg ~f:(fun cfg ->
        let module Cfg = (val cfg : Component_config) in
        Cfg.uninstall_user_subcommand ~component_name:Cfg.component_name
          ~subcommand_name:(Fmt.str "uninstall-user-%s" Cfg.component_name)
          ~setup_t)
    >>= fun uninstall_user_cmds ->
    Component_registry.eval reg ~f:(fun cfg ->
        let module Cfg = (val cfg : Component_config) in
        Cfg.install_admin_subcommand ~component_name:Cfg.component_name
          ~subcommand_name:(Fmt.str "install-admin-%s" Cfg.component_name)
          ~setup_t)
    >>= fun install_admin_cmds ->
    Component_registry.eval reg ~f:(fun cfg ->
        let module Cfg = (val cfg : Component_config) in
        Cfg.uninstall_admin_subcommand ~component_name:Cfg.component_name
          ~subcommand_name:(Fmt.str "uninstall-admin-%s" Cfg.component_name)
          ~setup_t)
    >>= fun uninstall_admin_cmds ->
    Result.ok
      (install_user_cmds @ uninstall_user_cmds @ install_admin_cmds
     @ uninstall_admin_cmds)
  in
  match cmd_results with Ok cmds -> cmds | Error msg -> failwith msg

let () = Term.(exit @@ eval_choice default_cmd (help_cmd :: component_cmds))
