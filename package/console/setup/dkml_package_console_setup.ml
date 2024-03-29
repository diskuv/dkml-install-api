open Bos
open Dkml_install_register
open Dkml_install_api

(* Load dkml-install-api module so that Dynlink access control
   does not prohibit plugins (components) from loading it by
   raising a Dynlink.Unavailable_unit error.

   Confer:
   https://ocaml.org/api/Dynlink.html#1_Accesscontrol "set_allowed_units" *)
let (_ : string list) = Default_component_config.install_depends_on

(* Create command line options for dkml-install-{user,admin}-runner.exe *)

(* Entry point of CLI.

   Logging is configured just before this function is called through Cmdliner
   Term evaluation of `log_config`. If you don't see log statement, make
   sure the log statements are created inside (or after) `setup ...`. *)
let setup target_abi program_version organization program_name program_assets
    program_info package_args : unit =
  let open Dkml_install_runner.Error_handling.Monad_syntax in
  (* deconstruct *)
  let ( prefix_opt,
        component_selector,
        static_files_source,
        staging_files_source,
        log_config ) =
    ( package_args.Dkml_package_console_common.prefix_opt,
      package_args.component_selector,
      package_args.static_files_source,
      package_args.staging_files_source,
      package_args.log_config )
  in

  Logs.debug (fun l -> l "Starting setup");

  (* Get all the available components. Logging has already been setup. *)
  let reg = Component_registry.get () in

  (* Only install what was specified, if specified *)
  let selector =
    Dkml_install_runner.Cmdliner_runner.to_selector component_selector
  in

  let install_sequence _fl : unit Forward_progress.t =
    let open Dkml_package_console_common in
    let map_string_error_to_progress, map_rresult_error_to_progress =
      ( Dkml_install_runner.Error_handling.map_string_error_to_progress,
        Dkml_install_runner.Error_handling.map_rresult_error_to_progress )
    in
    let* prefix_dir, _fl =
      Dkml_package_console_common.get_user_installation_prefix ~program_name
        ~target_abi ~prefix_opt
    in
    let args =
      Dkml_install_runner.Cmdliner_runner.common_runner_args ~log_config
        ~prefix_dir ~staging_files_source
    in
    let* archive_dir, _fl =
      Dkml_install_runner.Cmdliner_runner.enduser_archive_dir ()
    in

    let exe_cmd s = Cmd.v Fpath.(to_string (archive_dir / "bin" / s)) in

    let spawn_admin_if_needed () =
      let open Dkml_package_console_common in
      let* needs, _fl =
        needs_install_admin ~reg ~target_abi ~selector ~log_config ~prefix_dir
          ~archive_dir ~staging_files_source
      in
      let* ec, fl =
        elevated_cmd ~target_abi ~staging_files_source
          Cmd.(
            exe_cmd "dkml-install-admin-runner.exe"
            % "install-adminall"
            %% of_list (Array.to_list args))
      in
      if needs then spawn ec else Forward_progress.return ((), fl)
    in

    (* Validate *)
    Component_registry.validate reg Dkml_install_register.Install;
    (* Diagnostics *)
    let* (_ : unit list), _fl =
      Component_registry.install_eval reg ~selector
        ~fl:Dkml_install_runner.Error_handling.runner_fatal_log ~f:(fun cfg ->
          let module Cfg = (val cfg : Component_config) in
          Logs.debug (fun m -> m "Will install component %s" Cfg.component_name);
          return ())
    in
    (* The uninstaller may or may not be embedded. *)
    let uninstall_exe =
      Fpath.(archive_dir / "bin" / "dkml-package-uninstall.exe")
    in
    let* is_uninstall_embedded, _fl =
      map_rresult_error_to_progress (Bos.OS.File.exists uninstall_exe)
    in
    let* (), _fl =
      if is_uninstall_embedded then
        (* Copy uninstaller into <prefix> *)
        let* (), _fl =
          map_string_error_to_progress
            (Diskuvbox.copy_file ~err:box_err ~src:uninstall_exe
               ~dst:Fpath.(prefix_dir / "uninstall.exe")
               ())
        in
        (* Write uninstaller into Windows registry *)
        let* (), _fl =
          Windows_registry.Add_remove_programs.write_program_entry
            ~installation_prefix:prefix_dir ~organization ~program_name
            ~program_assets ~program_version ~program_info
        in
        return ()
      else return ()
    in
    (* Run admin-runner.exe commands *)
    let* (), _fl = spawn_admin_if_needed () in
    (* Copy <static>/<component> into <prefix>, if present *)
    let* (_ : unit list), _fl =
      Component_registry.install_eval reg ~selector
        ~fl:Dkml_install_runner.Error_handling.runner_fatal_log ~f:(fun cfg ->
          let open Dkml_install_runner.Error_handling.Monad_syntax in
          let module Cfg = (val cfg : Component_config) in
          let static_dir_fp =
            Dkml_install_runner.Path_location.absdir_static_files
              ~component_name:Cfg.component_name static_files_source
          in
          let* exists, _fl =
            Dkml_install_runner.Error_handling.map_msg_error_to_progress
            @@ OS.File.exists static_dir_fp
          in
          let+ () =
            if exists then
              map_string_error_to_progress
                (Diskuvbox.copy_dir ~err:box_err ~src:static_dir_fp
                   ~dst:prefix_dir ())
            else return ()
          in
          ())
    in
    (* Run user-runner.exe *)
    let* (_ : unit list), fl =
      Component_registry.install_eval reg ~selector
        ~fl:Dkml_install_runner.Error_handling.runner_fatal_log ~f:(fun cfg ->
          let module Cfg = (val cfg : Component_config) in
          Dkml_package_console_common.spawn
            Cmd.(
              exe_cmd "dkml-install-user-runner.exe"
              % ("install-user-" ^ Cfg.component_name)
              %% of_list (Array.to_list args)))
    in
    Forward_progress.return ((), fl)
  in
  match
    Forward_progress.catch_exceptions ~id:"7a222f5c"
      Dkml_install_runner.Error_handling.runner_fatal_log install_sequence
  with
  | Forward_progress.Completed | Continue_progress ((), _) ->
      Logs.debug (fun l -> l "Finished setup");
      ()
  | Halted_progress ec ->
      Logs.debug (fun l -> l "Finished setup in error");
      exit (Forward_progress.Exit_code.to_int_exitcode ec)
