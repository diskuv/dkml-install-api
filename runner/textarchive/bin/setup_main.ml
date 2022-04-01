open Bos
open Cmdliner
open Dkml_install_register
open Dkml_install_api
open Runner.Cmdliner_runner
open Runner.Error_handling
open Runner.Error_handling.Monad_syntax

(* Load dkml-install-api module so that Dynlink access control
   does not prohibit plugins (components) from loading it by
   raising a Dynlink.Unavailable_unit error.

   Confer:
   https://ocaml.org/api/Dynlink.html#1_Accesscontrol "set_allowed_units" *)
let (_ : string list) = Default_component_config.depends_on

(* Create command line options for dkml-install-{user,admin}-runner.exe *)

let name_t =
  let doc = "The name of the program to install" in
  Arg.(required & opt (some string) None & info [ "name" ] ~doc)

(* Entry point of CLI.

   Logging is configured just before this function is called through Cmdliner
   Term evaluation of `log_config`. If you don't see log statement, make
   sure the log statements are created inside (or after) `setup ...`. *)
let setup log_config name prefix component_selector static_files_source
    staging_files_source =
  (* Load all the available components. Logging has already been setup. *)
  Dkml_install_runner_sites.load_all ();
  let reg = Component_registry.get () in

  (* Only install what was specified, if specified *)
  let selector = to_selector component_selector in

  let args =
    Runner.Cmdliner_runner.common_runner_args ~log_config ~prefix
      ~staging_files_source
  in

  let exe_cmd s = Cmd.v Fpath.(to_string @@ (installer_archive_dir / s)) in

  let prefix_fp = Runner.Os_utils.string_to_norm_fpath prefix in
  let spawn_admin_if_needed () =
    if
      Textarchive_common.needs_install_admin ~reg ~selector ~log_config
        ~prefix ~staging_files_source
    then
      Textarchive_common.spawn
      @@ Textarchive_common.elevated_cmd ~staging_files_source
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
          let* static_dir_fp =
            map_msg_error_to_string @@ Fpath.of_string
            @@ Runner.Path_location.absdir_static_files
                 ~component_name:Cfg.component_name static_files_source
          in
          let* exists =
            map_msg_error_to_string @@ OS.File.exists static_dir_fp
          in
          let+ () =
            if exists then Runner.Os_utils.copy_dir static_dir_fp prefix_fp
            else Result.ok ()
          in
          ())
    in
    (* Run user-runner.exe *)
    let+ (_ : unit list) =
      Component_registry.eval reg ~selector ~f:(fun cfg ->
          let module Cfg = (val cfg : Component_config) in
          Textarchive_common.spawn
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
           (Fmt.str "@[Could not install %s.@]@,@[%a@]" name Fmt.lines e))

let setup_cmd =
  let doc = "the OCaml installer" in
  ( Term.(
      const setup $ setup_log_t $ name_t $ prefix_t
      $ component_selector_t ~install:true
      $ static_files_source_for_package_t
      $ staging_files_source_for_package_t),
    Term.info "dkml-install-setup" ~version:"%%VERSION%%" ~doc )

let () =
  Term.(
    exit
    @@ catch_cmdliner_eval (fun () -> eval ~catch:false setup_cmd) (`Error `Exn))
