open Dkml_install_register
open Dkml_install_api
open Dkml_install_runner.Cmdliner_runner
open Dkml_install_runner.Error_handling.Monad_syntax
module Term = Cmdliner.Term

let default_cmd ~program_version =
  let doc = "the OCaml CLI administrator installer" in
  let sdocs = Cmdliner.Manpage.s_common_options in
  let exits = Term.default_exits in
  let man = help_secs in
  ( Term.(ret (const (fun _log_config -> `Help (`Pager, None)) $ setup_log_t)),
    Term.info "dkml-install-admin-runner" ~version:program_version ~doc ~sdocs
      ~exits ~man )

(** {1 Setup}

  Install all non-administrative CLI subcommands for all the components.
  Even though all CLI subcommands are registered, setup.exe (setup_main) will
  only ask for some of the components if the --component option is used. *)

let install_admin_cmds ~reg ~target_abi ~selector =
  Dkml_install_runner.Error_handling.continue_or_exit
  @@ Component_registry.install_eval reg ~selector
       ~fl:Dkml_install_runner.Error_handling.runner_fatal_log ~f:(fun cfg ->
         let module Cfg = (val cfg : Component_config) in
         Cfg.install_admin_subcommand ~component_name:Cfg.component_name
           ~subcommand_name:(Fmt.str "install-admin-%s" Cfg.component_name)
           ~fl:Dkml_install_runner.Error_handling.runner_fatal_log
           ~ctx_t:
             (ctx_for_runner_t ~install_direction:Install ~target_abi
                Cfg.component_name reg))

let uninstall_admin_cmds ~reg ~target_abi ~selector =
  Dkml_install_runner.Error_handling.continue_or_exit
  @@ Component_registry.uninstall_eval reg ~selector
       ~fl:Dkml_install_runner.Error_handling.runner_fatal_log ~f:(fun cfg ->
         let module Cfg = (val cfg : Component_config) in
         Cfg.uninstall_admin_subcommand ~component_name:Cfg.component_name
           ~subcommand_name:(Fmt.str "uninstall-admin-%s" Cfg.component_name)
           ~fl:Dkml_install_runner.Error_handling.runner_fatal_log
           ~ctx_t:
             (ctx_for_runner_t ~install_direction:Uninstall ~target_abi
                Cfg.component_name reg))

(* For admin we have {un}install-adminall commands to do all the components
   at once. This is important since on Win32 we want only one
   User Account Control prompt and on Unix we only want one sudo password
   prompt. Drawback is that progress is a bit harder to track; we'll survive! *)

let run_terms_with_common_runner_args ~log_config ~prefix ~staging_files_source
    acc (term_t, term_info) =
  let common_runner_cmd =
    Dkml_install_runner.Cmdliner_runner.common_runner_args ~log_config ~prefix
      ~staging_files_source
  in
  let common_runner_args =
    Array.of_list (Term.name term_info :: Bos.Cmd.to_list common_runner_cmd)
  in
  match acc with
  | `Ok () -> (
      let name = Term.name term_info in
      match
        Term.(eval ~argv:common_runner_args ~catch:false (term_t, term_info))
      with
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

let helper_all_cmd ~doc ~name ~install_direction ~program_version f =
  let runall log_config selector prefix staging_files_opt opam_context_opt =
    let* staging_files_source, _fl =
      Dkml_install_runner.Path_location.staging_files_source
        ~staging_default:No_staging_default ~opam_context_opt ~staging_files_opt
    in
    return
      (List.fold_left
         (run_terms_with_common_runner_args ~log_config ~prefix
            ~staging_files_source)
         (`Ok ())
         (f ~selector:(to_selector selector)))
  in
  ( Term.(
      ret
        (Dkml_install_runner.Cmdliner_runner.unwrap_progress_nodefault_t
           (const runall $ setup_log_t
           $ component_selector_t ~install_direction
           $ prefix_t $ staging_files_opt_t $ opam_context_opt_t))),
    Term.info name ~version:program_version ~doc )

let install_all_cmd ~reg ~target_abi =
  let doc = "install all components" in
  helper_all_cmd ~name:"install-adminall" ~doc
    ~install_direction:Dkml_install_runner.Path_eval.Global_context.Install
    (install_admin_cmds ~reg ~target_abi)

let uninstall_all_cmd ~reg ~target_abi =
  let doc = "uninstall all components" in
  helper_all_cmd ~name:"uninstall-adminall" ~doc
    ~install_direction:Dkml_install_runner.Path_eval.Global_context.Uninstall
    (uninstall_admin_cmds ~reg ~target_abi)

let main ~target_abi ~program_version =
  (* Initial logger. Cmdliner evaluation of setup_log_t (through ctx_t) will
     reset the logger to what was given on the command line. *)
  let (_ : Log_config.t) =
    Dkml_install_runner.Cmdliner_runner.setup_log None None
  in
  Logs.info (fun m ->
      m "Installing administrator-permissioned components with target ABI %s"
        (Context.Abi_v2.to_canonical_string target_abi));
  (* Get all the available components *)
  let reg = Component_registry.get () in
  let open Dkml_install_runner.Error_handling in
  Component_registry.validate reg;
  Term.(
    exit
    @@ catch_and_exit_on_error ~id:"0c9ebd09" (fun () ->
           (* [install_all_cmd] and [uninstall_all_cmd] will only use
              CLI specified components. [install_admin_cmds] and
              [uninstall_admin_cmds] will use _all_ components, which means
              any individual component can be installed and uninstalled
              by invoking the individual subcommand. *)
           eval_choice ~catch:false
             (default_cmd ~program_version)
             (help_cmd
              :: install_all_cmd ~reg ~target_abi ~program_version
              :: uninstall_all_cmd ~reg ~target_abi ~program_version
              :: install_admin_cmds ~reg ~target_abi ~selector:All_components
             @ uninstall_admin_cmds ~reg ~target_abi ~selector:All_components)))
