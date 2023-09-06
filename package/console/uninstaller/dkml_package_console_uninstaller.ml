open Bos
open Dkml_install_register
open Dkml_install_api

(* Load dkml-install-api module so that Dynlink access control
   does not prohibit plugins (components) from loading it by
   raising a Dynlink.Unavailable_unit error.

   Confer:
   https://ocaml.org/api/Dynlink.html#1_Accesscontrol "set_allowed_units" *)
let (_ : string list) = Default_component_config.uninstall_depends_on

(* Create command line options for dkml-install-{user,admin}-runner.exe *)

(* Entry point of CLI.

   Logging is configured just before this function is called through Cmdliner
   Term evaluation of `log_config`. If you don't see log statement, make
   sure the log statements are created inside (or after) `setup ...`. *)
let uninstall target_abi program_name package_args : unit =
  let open Dkml_install_runner.Error_handling.Monad_syntax in
  (* deconstruct *)
  let prefix_opt, component_selector, staging_files_source, log_config =
    ( package_args.Dkml_package_console_common.prefix_opt,
      package_args.component_selector,
      package_args.staging_files_source,
      package_args.log_config )
  in

  (* Get all the available components *)
  let reg = Component_registry.get () in

  (* Only uninstall what was specified, if specified *)
  let selector =
    Dkml_install_runner.Cmdliner_runner.to_selector component_selector
  in

  let uninstall_sequence _fl : unit Forward_progress.t =
    let* prefix_dir, _fl =
      Dkml_package_console_common.get_user_installation_prefix ~program_name
        ~target_abi ~prefix_opt
    in
    let* archive_dir, _fl =
      Dkml_install_runner.Cmdliner_runner.enduser_archive_dir ()
    in
    let args =
      Dkml_install_runner.Cmdliner_runner.common_runner_args ~log_config
        ~prefix_dir ~staging_files_source
    in

    let exe_cmd s = Cmd.v Fpath.(to_string (archive_dir / "bin" / s)) in

    let spawn_admin_if_needed () =
      let open Dkml_package_console_common in
      let* needs, _fl =
        needs_uninstall_admin ~reg ~target_abi ~selector ~log_config ~prefix_dir
          ~archive_dir ~staging_files_source
      in
      let* ec, fl =
        elevated_cmd ~target_abi ~staging_files_source
          Cmd.(
            exe_cmd "dkml-install-admin-runner.exe"
            % "uninstall-adminall"
            %% of_list (Array.to_list args))
      in
      if needs then spawn ec else Forward_progress.return ((), fl)
    in
    (* Validate *)
    Component_registry.validate reg;
    (* Diagnostics *)
    let* (_ : unit list), _fl =
      Component_registry.uninstall_eval reg ~selector
        ~fl:Dkml_install_runner.Error_handling.runner_fatal_log ~f:(fun cfg ->
          let module Cfg = (val cfg : Component_config) in
          Logs.debug (fun m ->
              m "Will uninstall component %s" Cfg.component_name);
          return ())
    in
    (* Run user-runner.exe *)
    let* (_ : unit list), _fl =
      Component_registry.uninstall_eval reg ~selector
        ~fl:Dkml_install_runner.Error_handling.runner_fatal_log ~f:(fun cfg ->
          let module Cfg = (val cfg : Component_config) in
          Dkml_package_console_common.spawn
            Cmd.(
              exe_cmd "dkml-install-user-runner.exe"
              % ("uninstall-user-" ^ Cfg.component_name)
              %% of_list (Array.to_list args)))
    in
    (* Run admin-runner.exe commands *)
    let* (), _fl = spawn_admin_if_needed () in
    (* Delete the Add/Remove Programs entry *)
    Dkml_package_console_common.Windows_registry.Add_remove_programs
    .delete_program_entry ~program_name
  in
  match
    Forward_progress.catch_exceptions ~id:"b8738356"
      Dkml_install_runner.Error_handling.runner_fatal_log uninstall_sequence
  with
  | Forward_progress.Completed | Continue_progress ((), _) ->
      Logs.debug (fun l -> l "Finished uninstall")
  | Halted_progress ec ->
      Logs.debug (fun l -> l "Finished uninstall in error");
      exit (Forward_progress.Exit_code.to_int_exitcode ec)
