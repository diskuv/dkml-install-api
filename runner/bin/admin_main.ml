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

(* Initial logger. Cmdliner evaluation of setup_log_t (through ctx_t) will
   reset the logger to what was given on the command line. *)
let (_ : Log_config.t) = Runner.Cmdliner_runner.setup_log None None

(* Load all the available components *)
let () = Dkml_install_runner_sites.load_all ()

let reg = Component_registry.get ()

let () =
  Runner.Error_handling.get_ok_or_raise_string (Component_registry.validate reg)

(** {1 Setup}

  Install all non-administrative CLI subcommands for all the components.
  Even though all CLI subcommands are registered, setup.exe (setup_main) will
  only ask for some of the components if the --component option is used. *)

let install_admin_cmds ~selector =
  let cmd_results =
    Component_registry.eval reg ~selector ~f:(fun cfg ->
        let module Cfg = (val cfg : Component_config) in
        Cfg.install_admin_subcommand ~component_name:Cfg.component_name
          ~subcommand_name:(Fmt.str "install-admin-%s" Cfg.component_name)
          ~ctx_t:(ctx_t Cfg.component_name reg))
  in
  match cmd_results with
  | Ok cmds -> cmds
  | Error msg -> raise (Installation_error msg)

let uninstall_admin_cmds ~selector =
  let cmd_results =
    Component_registry.reverse_eval reg ~selector ~f:(fun cfg ->
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

let run_terms_with_common_runner_args ~log_config ~prefix ~staging_files_source
    acc (term_t, term_info) =
  let common_runner_cmd =
    Runner.Cmdliner_runner.common_runner_args ~log_config ~prefix
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

let helper_all_cmd ~doc ~name ~install f =
  let runall log_config selector prefix staging_files_opt opam_context_opt =
    let staging_files_source =
      Runner.Path_location.staging_files_source ~opam_context_opt
        ~staging_files_opt
    in
    List.fold_left
      (run_terms_with_common_runner_args ~log_config ~prefix
         ~staging_files_source)
      (`Ok ())
      (f ~selector:(to_selector selector))
  in
  ( Term.(
      ret
        (const runall $ setup_log_t
        $ component_selector_t ~install
        $ prefix_t $ staging_files_opt_t $ opam_context_opt_t)),
    Term.info name ~version:"%%VERSION%%" ~doc )

let install_all_cmd =
  let doc = "install all components" in
  helper_all_cmd ~name:"install-adminall" ~doc ~install:true install_admin_cmds

let uninstall_all_cmd =
  let doc = "uninstall all components" in
  helper_all_cmd ~name:"uninstall-adminall" ~doc ~install:false
    uninstall_admin_cmds

let () =
  Term.(
    exit
    @@ catch_cmdliner_eval
         (fun () ->
           (* [install_all_cmd] and [uninstall_all_cmd] will only use
              CLI specified components. [install_admin_cmds] and
              [uninstall_admin_cmds] will use _all_ components, which means
              any individual component can be installed and uninstalled
              by invoking the individual subcommand. *)
           eval_choice ~catch:false default_cmd
             (help_cmd :: install_all_cmd :: uninstall_all_cmd
              :: install_admin_cmds ~selector:All_components
             @ uninstall_admin_cmds ~selector:All_components))
         (`Error `Exn))
