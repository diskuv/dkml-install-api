open Bos
open Dkml_install_register
open Dkml_install_api

(* Load dkml-install-api module so that Dynlink access control
   does not prohibit plugins (components) from loading it by
   raising a Dynlink.Unavailable_unit error.

   Confer:
   https://ocaml.org/api/Dynlink.html#1_Accesscontrol "set_allowed_units" *)
let (_ : string list) = Default_component_config.depends_on

(* Create command line options for dkml-install-{user,admin}-runner.exe *)

(* Entry point of CLI.

   Logging is configured just before this function is called through Cmdliner
   Term evaluation of `log_config`. If you don't see log statement, make
   sure the log statements are created inside (or after) `setup ...`. *)
let setup target_abi program_name package_args =
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

  let prefix =
    Dkml_package_console_common.get_user_installation_prefix ~program_name
      ~target_abi ~prefix_opt
  in
  let args =
    Dkml_install_runner.Cmdliner_runner.common_runner_args ~log_config ~prefix
      ~staging_files_source
  in

  let exe_cmd s =
    Cmd.v
      Fpath.(
        to_string
        @@ Dkml_install_runner.Cmdliner_runner.enduser_archive_dir ()
           / "bin" / s)
  in

  let ( let* ) = Forward_progress.bind in

  let spawn_admin_if_needed fl =
    let open Dkml_package_console_common in
    if
      needs_install_admin ~reg ~target_abi ~selector ~log_config ~prefix
        ~staging_files_source
    then
      spawn fl
      @@ elevated_cmd ~target_abi ~staging_files_source
           Cmd.(
             exe_cmd "dkml-install-admin-runner.exe"
             % "install-adminall" %% args)
    else Forward_progress.return ((), fl)
  in
  let install_sequence fl : unit Forward_progress.t =
    let open Dkml_package_console_common in
    let open Forward_progress in
    let efmt fmt =
      Fmt.pf fmt "@[Could not install %s.@]@,@[%a@]@." program_name.name_full
        Fmt.lines
    in
    (* Validate *)
    let* (), fl =
      lift_result __POS__ efmt fl (Component_registry.validate reg)
    in
    (* Diagnostics *)
    let* (_ : unit list), fl =
      lift_result __POS__ efmt fl
        (Component_registry.eval reg ~selector ~f:(fun cfg ->
             let module Cfg = (val cfg : Component_config) in
             Result.ok
             @@ Logs.debug (fun m ->
                    m "Will install component %s" Cfg.component_name)))
    in
    (* Run admin-runner.exe commands *)
    let* (), fl = spawn_admin_if_needed fl in
    (* Copy <static>/<component> into <prefix>, if present *)
    let* (_ : unit list), fl =
      lift_result __POS__ efmt fl
        (Component_registry.eval reg ~selector ~f:(fun cfg ->
             let open Dkml_install_runner.Error_handling.Monad_syntax in
             let module Cfg = (val cfg : Component_config) in
             let static_dir_fp =
               Dkml_install_runner.Path_location.absdir_static_files
                 ~component_name:Cfg.component_name static_files_source
             in
             let* exists =
               Dkml_install_runner.Error_handling.map_msg_error_to_string
               @@ OS.File.exists static_dir_fp
             in
             let+ () =
               if exists then
                 Diskuvbox.copy_dir ~err:box_err ~src:static_dir_fp ~dst:prefix
                   ()
               else Result.ok ()
             in
             ()))
    in
    (* Run user-runner.exe *)
    let* (_ : unit list), fl =
      lift_result __POS__ efmt fl
        (Component_registry.eval reg ~selector ~f:(fun cfg ->
             let module Cfg = (val cfg : Component_config) in
             match
               Dkml_package_console_common.spawn fl
                 Cmd.(
                   exe_cmd "dkml-install-user-runner.exe"
                   % ("install-user-" ^ Cfg.component_name)
                   %% args)
             with
             | Continue_progress _ | Completed -> Ok ()
             | Halted_progress ec ->
                 Error
                   (Fmt.str
                      "Install was halted in dkml-install-user-runner.exe. %s"
                      (Exit_code.to_short_sentence ec))))
    in
    Forward_progress.return ((), fl)
  in
  let fl ~id s = Logs.err (fun l -> l "FATAL [%s]. %s" id s) in
  match
    Forward_progress.catch_exceptions ~id:"7a222f5c" fl install_sequence
  with
  | Forward_progress.Completed | Continue_progress _ ->
      Logs.debug (fun l -> l "Finished setup");
      ()
  | Halted_progress ec ->
      Logs.debug (fun l -> l "Finished setup in error");
      exit (Forward_progress.Exit_code.to_int_exitcode ec)
