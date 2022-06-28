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
let uninstall target_abi program_name package_args =
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

  let spawn_admin_if_needed () =
    let open Dkml_package_console_common in
    if
      needs_uninstall_admin ~reg ~target_abi ~selector ~log_config ~prefix
        ~staging_files_source
    then
      spawn
      @@ elevated_cmd ~target_abi ~staging_files_source
           Cmd.(
             exe_cmd "dkml-install-admin-runner.exe"
             % "uninstall-adminall" %% args)
    else Continue_program
  in
  let install_sequence =
    let open Dkml_package_console_common in
    let ( >>= ) = bind_program_control in
    let lift_result : ('a, string) result -> program_control = function
      | Ok _ -> Continue_program
      | Error v ->
          Fmt.epr "@[Could not uninstall %s.@]@,@[%a@]@." program_name.name_full
            Fmt.lines v;
          Exit_code 1
    in
    let map_unit_list : (unit list, string) result -> (unit, string) result =
      function
      | Ok (_ : unit list) -> Ok ()
      | Error e -> Error e
    in
    (* Validate *)
    lift_result (Component_registry.validate reg) >>= fun () ->
    (* Diagnostics *)
    lift_result @@ map_unit_list
    @@ Component_registry.reverse_eval reg ~selector ~f:(fun cfg ->
           let module Cfg = (val cfg : Component_config) in
           Result.ok
           @@ Logs.debug (fun m ->
                  m "Will uninstall component %s" Cfg.component_name))
    >>= fun () ->
    (* Run user-runner.exe *)
    lift_result @@ map_unit_list
    @@ Component_registry.reverse_eval reg ~selector ~f:(fun cfg ->
           let module Cfg = (val cfg : Component_config) in
           match
             Dkml_package_console_common.spawn
               ~print_errors_and_controlled_exit:true
               Cmd.(
                 exe_cmd "dkml-install-user-runner.exe"
                 % ("uninstall-user-" ^ Cfg.component_name)
                 %% args)
           with
           | Continue_program | Exit_code 0 -> Ok ()
           | Exit_code ec ->
               Error
                 (Fmt.str
                    "Exited from dkml-install-user-runner.exe wth exit code %d"
                    ec))
    >>= fun () ->
    (* Run admin-runner.exe commands *)
    spawn_admin_if_needed ()
  in
  match install_sequence with
  | Dkml_package_console_common.Continue_program
  | Dkml_package_console_common.Exit_code 0 ->
      Logs.debug (fun l -> l "Finished uninstall");
      ()
  | Dkml_package_console_common.Exit_code ec ->
      Logs.debug (fun l -> l "Finished uninstall in error");
      exit ec
