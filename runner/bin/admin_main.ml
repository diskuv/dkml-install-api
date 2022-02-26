open Cmdliner
open Dkml_install_register
open Dkml_install_api
open Runner.Cmdliner_runner
open Runner.Error_handling

let default_cmd =
  let doc = "the OCaml CLI administrator installer" in
  let sdocs = Manpage.s_common_options in
  let exits = Term.default_exits in
  let man = help_secs in
  ( Term.(ret (const (fun _log_config -> `Help (`Pager, None)) $ setup_log_t)),
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

let install_admin_cmds =
  let cmd_results =
    Component_registry.eval reg ~f:(fun cfg ->
        let module Cfg = (val cfg : Component_config) in
        Cfg.install_admin_subcommand ~component_name:Cfg.component_name
          ~subcommand_name:(Fmt.str "install-admin-%s" Cfg.component_name)
          ~ctx_t:(ctx_t Cfg.component_name reg))
  in
  match cmd_results with
  | Ok cmds -> cmds
  | Error msg -> raise (Installation_error msg)

let uninstall_admin_cmds =
  let cmd_results =
    Component_registry.reverse_eval reg ~f:(fun cfg ->
        let module Cfg = (val cfg : Component_config) in
        Cfg.uninstall_admin_subcommand ~component_name:Cfg.component_name
          ~subcommand_name:(Fmt.str "uninstall-admin-%s" Cfg.component_name)
          ~ctx_t:(ctx_t Cfg.component_name reg))
  in
  match cmd_results with
  | Ok cmds -> cmds
  | Error msg -> raise (Installation_error msg)

(* For admin we have {un}install-adminall commands to do all the components
   at once. This is important since on Win32 we want only one
   User Account Control prompt and on Unix we only want one sudo password
   prompt. Drawback is that progress is a bit harder to track; we'll survive! *)

let run_terms acc (term_t, term_info) =
  match acc with
  | `Ok () -> (
      let name = Term.name term_info in
      match Term.(eval ~catch:false (term_t, term_info)) with
      | `Ok () -> `Ok ()
      | `Error `Exn ->
          `Error (false, Fmt.str "Terminated with an exception in %s" name)
      | `Error `Parse ->
          `Error (false, Fmt.str "Terminated due to parsing problems in %s" name)
      | `Error `Term ->
          `Error
            (false, Fmt.str "Ended with an unsuccessful exit code in %s" name)
      | `Version -> `Help (`Pager, None)
      | `Help -> `Help (`Pager, None))
  | _ as a -> a

let install_all_cmd =
  let doc = "install all components" in
  let runall () = List.fold_left run_terms (`Ok ()) install_admin_cmds in
  Term.
    ( ret (const runall $ const ()),
      info "install-adminall" ~version:"%%VERSION%%" ~doc )

let uninstall_all_cmd =
  let doc = "uninstall all components" in
  let runall () = List.fold_left run_terms (`Ok ()) uninstall_admin_cmds in
  Term.
    ( ret (const runall $ const ()),
      info "uninstall-adminall" ~version:"%%VERSION%%" ~doc )

let () =
  Term.(
    exit
    @@ catch_cmdliner_eval
         (fun () ->
           eval_choice ~catch:false default_cmd
             (help_cmd :: install_all_cmd :: uninstall_all_cmd
              :: install_admin_cmds
             @ uninstall_admin_cmds))
         (`Error `Exn))
