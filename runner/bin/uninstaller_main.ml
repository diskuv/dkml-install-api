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
  let doc = "The name of the program to uninstall" in
  Arg.(required & opt (some string) None & info [ "name" ] ~doc)

(* Entry point of CLI.

   Logging is configured just before this function is called through Cmdliner
   Term evaluation of `log_config`. If you don't see log statement, make
   sure the log statements are created inside (or after) `setup ...`. *)
let setup log_config name prefix staging_files_source =
  (* Load all the available components *)
  Uninstaller_sites.Plugins.Plugins.load_all ();
  let reg = Component_registry.get () in

  let args =
    Runner.Component_utils.common_runner_args ~log_config ~prefix
      ~staging_files_source
  in

  let exe_cmd s = Cmd.v Fpath.(to_string @@ (archive_dir_for_setup / s)) in

  let spawn_admin_if_needed () =
    if Runner.Component_utils.needs_install_admin reg then
      Runner.Component_utils.spawn
      @@ Runner.Component_utils.elevated_cmd
           Cmd.(
             exe_cmd "dkml-install-admin-runner.exe"
             % "uninstall-adminall" %% args)
    else Result.ok ()
  in
  let install_sequence =
    (* Validate *)
    let* () = Component_registry.validate reg in
    (* Run user-runner.exe *)
    let* (_ : unit list) =
      Component_registry.eval reg ~f:(fun cfg ->
          let module Cfg = (val cfg : Component_config) in
          Runner.Component_utils.spawn
            Cmd.(
              exe_cmd "dkml-install-user-runner.exe"
              % ("uninstall-user-" ^ Cfg.component_name)
              %% args))
    in
    (* Run admin-runner.exe commands *)
    spawn_admin_if_needed ()
  in
  match install_sequence with
  | Ok _ -> ()
  | Error e ->
      raise
        (Installation_error
           (Fmt.str "@[Could not uninstall %s.@]@,@[%a@]" name Fmt.lines e))

let uninstall_cmd =
  let doc = "the OCaml uninstaller" in
  ( Term.(
      const setup $ setup_log_t $ name_t $ prefix_t
      $ staging_files_source_for_setup_and_uninstaller_t),
    Term.info "dkml-install-uninstaller" ~version:"%%VERSION%%" ~doc )

let () =
  Term.(
    exit
    @@ catch_cmdliner_eval
         (fun () -> eval ~catch:false uninstall_cmd)
         (`Error `Exn))
