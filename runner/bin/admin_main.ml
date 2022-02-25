open Cmdliner
open Dkml_install_register
open Dkml_install_api
open Runner.Cmdliner_runner
open Runner.Error_handling
open Runner.Error_handling.Let_syntax

(* This is a error='polymorphic bind *)
let ( >>= ) = Result.bind

(* This is a error=string bind *)
let ( let* ) = Let_syntax.bind

(* This is a error=string map *)
let ( let+ ) x f = Let_syntax.map f x

let default_cmd =
  let doc = "the OCaml CLI administrator installer" in
  let sdocs = Manpage.s_common_options in
  let exits = Term.default_exits in
  let man = help_secs in
  ( Term.(ret (const (fun () -> `Help (`Pager, None)) $ setup_log_t)),
    Term.info "dkml-install-admin-runner" ~version:"%%VERSION%%" ~doc ~sdocs
      ~exits ~man )

(* Load dkml-install-api module so that Dynlink access control
   does not prohibit plugins (components) from loading it by
   raising a Dynlink.Unavailable_unit error.

   Confer:
   https://ocaml.org/api/Dynlink.html#1_Accesscontrol "set_allowed_units" *)
let (_ : string list) = Default_component_config.depends_on

(* Load all the available components *)
let () = Admin_sites.Plugins.Plugins.load_all ()

let reg = Component_registry.get ()

(* Install all administrative CLI subcommands for all the components *)
let component_cmds =
  let cmd_results =
    let* install_admin_cmds =
      Component_registry.eval reg ~f:(fun cfg ->
          let module Cfg = (val cfg : Component_config) in
          Cfg.install_admin_subcommand ~component_name:Cfg.component_name
            ~subcommand_name:(Fmt.str "install-admin-%s" Cfg.component_name)
            ~ctx_t:(ctx_t Cfg.component_name reg))
    in
    let* uninstall_admin_cmds =
      Component_registry.eval reg ~f:(fun cfg ->
          let module Cfg = (val cfg : Component_config) in
          Cfg.uninstall_admin_subcommand ~component_name:Cfg.component_name
            ~subcommand_name:(Fmt.str "uninstall-admin-%s" Cfg.component_name)
            ~ctx_t:(ctx_t Cfg.component_name reg))
    in
    Result.ok (install_admin_cmds @ uninstall_admin_cmds)
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
