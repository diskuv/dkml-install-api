open Bos
open Dkml_install_register
open Dkml_install_api
open Dkml_install_runner.Error_handling.Monad_syntax

(* Load dkml-install-api module so that Dynlink access control
   does not prohibit plugins (components) from loading it by
   raising a Dynlink.Unavailable_unit error.

   Confer:
   https://ocaml.org/api/Dynlink.html#1_Accesscontrol "set_allowed_units" *)
let (_ : string list) = Default_component_config.depends_on

let box_err s =
  Logs.err (fun l -> l "FATAL: %s" s);
  failwith s

(* Create command line options for dkml-install-{user,admin}-runner.exe *)

(* Entry point of CLI.

   Logging is configured just before this function is called through Cmdliner
   Term evaluation of `log_config`. If you don't see log statement, make
   sure the log statements are created inside (or after) `setup ...`. *)
let setup program_name package_args =
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

  (* Load all the available components. Logging has already been setup. *)
  Dkml_install_runner_sites.load_all ();
  let reg = Component_registry.get () in

  (* Only install what was specified, if specified *)
  let selector =
    Dkml_install_runner.Cmdliner_runner.to_selector component_selector
  in

  let prefix =
    Dkml_package_console_common.get_user_installation_prefix ~program_name
      ~prefix_opt
  in
  let args =
    Dkml_install_runner.Cmdliner_runner.common_runner_args ~log_config ~prefix
      ~staging_files_source
  in

  let exe_cmd s =
    Cmd.v
      Fpath.(
        to_string
        @@ (Dkml_install_runner.Cmdliner_runner.installer_archive_dir / s))
  in

  let spawn_admin_if_needed () =
    if
      Dkml_package_console_common.needs_install_admin ~reg ~selector ~log_config
        ~prefix ~staging_files_source
    then
      Dkml_package_console_common.spawn
      @@ Dkml_package_console_common.elevated_cmd ~staging_files_source
           Cmd.(
             exe_cmd "dkml-install-admin-runner.exe"
             % "install-adminall" %% args)
    else Result.ok ()
  in
  let install_sequence =
    (* Validate *)
    let* () = Component_registry.validate reg in
    (* Diagnostics *)
    let* (_ : unit list) =
      Component_registry.eval reg ~selector ~f:(fun cfg ->
          let module Cfg = (val cfg : Component_config) in
          Result.ok
          @@ Logs.debug (fun m ->
                 m "Will install component %s" Cfg.component_name))
    in
    (* Run admin-runner.exe commands *)
    let* () = spawn_admin_if_needed () in
    (* Copy <static>/<component> into <prefix>, if present *)
    let* (_ : unit list) =
      Component_registry.eval reg ~selector ~f:(fun cfg ->
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
              Diskuvbox.copy_dir ~err:box_err ~src:static_dir_fp
                ~dst:prefix ()
            else Result.ok ()
          in
          ())
    in
    (* Run user-runner.exe *)
    let+ (_ : unit list) =
      Component_registry.eval reg ~selector ~f:(fun cfg ->
          let module Cfg = (val cfg : Component_config) in
          Dkml_package_console_common.spawn
            Cmd.(
              exe_cmd "dkml-install-user-runner.exe"
              % ("install-user-" ^ Cfg.component_name)
              %% args))
    in
    ()
  in
  match install_sequence with
  | Ok _ -> ()
  | Error e ->
      raise
        (Installation_error
           (Fmt.str "@[Could not install %s.@]@,@[%a@]" program_name.name_full
              Fmt.lines e))

let create_installers = Create_installers.create_installers