open Cmdliner
open Dkml_install_register
open Dkml_install_api
open Runner.Cmdliner_runner
open Runner.Error_handling
open Runner.Error_handling.Monad_syntax

let default_cmd =
  let doc = "the OCaml CLI user installer" in
  let sdocs = Manpage.s_common_options in
  let exits = Term.default_exits in
  let man = help_secs in
  ( Term.(ret (const (fun _log_config -> `Help (`Pager, None)) $ setup_log_t)),
    Term.info "dkml-install-user-runner" ~version:"%%VERSION%%" ~doc ~sdocs
      ~exits ~man )

(* Load dkml-install-api module so that Dynlink access control
   does not prohibit plugins (components) from loading it by
   raising a Dynlink.Unavailable_unit error.

   Confer:
   https://ocaml.org/api/Dynlink.html#1_Accesscontrol "set_allowed_units" *)
let (_ : string list) = Default_component_config.depends_on

(* Initial logger. Cmdliner evaluation of setup_log_t (through ctx_t) will
   reset the logger to what was given on the command line. *)
let (_ : Log_config.t) = Runner.Cmdliner_runner.setup_log None None

(* Load all the available components *)
let () = Dkml_install_runner_sites.load_all ()

let reg = Component_registry.get ()

let () =
  Runner.Error_handling.get_ok_or_raise_string (Component_registry.validate reg)

(** Install all non-administrative CLI subcommands for all the components.
  Even though all CLI subcommands are registered, setup.exe (setup_main) will
  only ask for some of the components if the --component option is used. *)
let component_cmds =
  let selector = Component_registry.All_components in
  let cmd_results =
    let* install_user_cmds =
      Component_registry.eval reg ~selector ~f:(fun cfg ->
          let module Cfg = (val cfg : Component_config) in
          Cfg.install_user_subcommand ~component_name:Cfg.component_name
            ~subcommand_name:(Fmt.str "install-user-%s" Cfg.component_name)
            ~ctx_t:(ctx_for_runner_t Cfg.component_name reg))
    in
    let* uninstall_user_cmds =
      Component_registry.reverse_eval reg ~selector ~f:(fun cfg ->
          let module Cfg = (val cfg : Component_config) in
          Cfg.uninstall_user_subcommand ~component_name:Cfg.component_name
            ~subcommand_name:(Fmt.str "uninstall-user-%s" Cfg.component_name)
            ~ctx_t:(ctx_for_runner_t Cfg.component_name reg))
    in
    Result.ok (install_user_cmds @ uninstall_user_cmds)
  in
  match cmd_results with
  | Ok cmds -> cmds
  | Error msg -> raise (Installation_error msg)

let () =
  Term.(
    exit
    @@ catch_cmdliner_eval
         (fun () ->
           eval_choice ~catch:false default_cmd (help_cmd :: component_cmds))
         (`Error `Exn))
