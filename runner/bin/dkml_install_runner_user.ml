open Dkml_install_register
open Dkml_install_api
open Dkml_install_runner.Cmdliner_runner
open Dkml_install_runner.Error_handling.Monad_syntax
module Term = Cmdliner.Term

let default_cmd ~program_version =
  let doc = "the OCaml CLI user installer" in
  let sdocs = Cmdliner.Manpage.s_common_options in
  let exits = Term.default_exits in
  let man = help_secs in
  ( Term.(ret (const (fun _log_config -> `Help (`Pager, None)) $ setup_log_t)),
    Term.info "dkml-install-user-runner" ~version:program_version ~doc ~sdocs
      ~exits ~man )

(** Install all non-administrative CLI subcommands for all the components.
  Even though all CLI subcommands are registered, setup.exe (setup_main) will
  only ask for some of the components if the --component option is used. *)
let component_cmds ~reg ~target_abi =
  let selector = Component_registry.All_components in
  Dkml_install_runner.Error_handling.continue_or_exit
    (let* install_user_cmds, _fl =
       Component_registry.install_eval reg ~selector
         ~fl:Dkml_install_runner.Error_handling.runner_fatal_log ~f:(fun cfg ->
           let module Cfg = (val cfg : Component_config) in
           Cfg.install_user_subcommand ~component_name:Cfg.component_name
             ~subcommand_name:(Fmt.str "install-user-%s" Cfg.component_name)
             ~fl:Dkml_install_runner.Error_handling.runner_fatal_log
             ~ctx_t:
               (ctx_for_runner_t ~install_direction:Install ~target_abi
                  Cfg.component_name reg))
     in
     let* uninstall_user_cmds, _fl =
       Component_registry.uninstall_eval reg ~selector
         ~fl:Dkml_install_runner.Error_handling.runner_fatal_log ~f:(fun cfg ->
           let module Cfg = (val cfg : Component_config) in
           Cfg.uninstall_user_subcommand ~component_name:Cfg.component_name
             ~subcommand_name:(Fmt.str "uninstall-user-%s" Cfg.component_name)
             ~fl:Dkml_install_runner.Error_handling.runner_fatal_log
             ~ctx_t:
               (ctx_for_runner_t ~install_direction:Uninstall ~target_abi
                  Cfg.component_name reg))
     in
     return (install_user_cmds @ uninstall_user_cmds))

let main ~target_abi ~program_version =
  (* Initial logger. Cmdliner evaluation of setup_log_t (through ctx_t) will
     reset the logger to what was given on the command line. *)
  let (_ : Log_config.t) =
    Dkml_install_runner.Cmdliner_runner.setup_log None None
  in
  Logs.info (fun m ->
      m "Installing user-permissioned components with target ABI %s"
        (Context.Abi_v2.to_canonical_string target_abi));
  (* Get all the available components *)
  let reg = Component_registry.get () in
  let open Dkml_install_runner.Error_handling in
  Component_registry.validate reg;
  Term.(
    exit
    @@ catch_and_exit_on_error ~id:"f59b4702" (fun () ->
           eval_choice ~catch:false
             (default_cmd ~program_version)
             (help_cmd :: component_cmds ~reg ~target_abi)))
