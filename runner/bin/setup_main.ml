open Cmdliner
open Dkml_install_register
open Dkml_install_api
open Runner.Cmdliner_runner
open Bos
open Runner.Error_handling
open Runner.Error_handling.Monad_syntax

(* Load dkml-install-api module so that Dynlink access control
   does not prohibit plugins (components) from loading it by
   raising a Dynlink.Unavailable_unit error.

   Confer:
   https://ocaml.org/api/Dynlink.html#1_Accesscontrol "set_allowed_units" *)
let (_ : string list) = Default_component_config.depends_on

(* Load all the available components *)
let () = Setup_sites.Plugins.Plugins.load_all ()

let reg = Component_registry.get ()

(* Check all components to see if _any_ needs admin *)
let needs_install_admin =
  let at_least_one_component_needs_admin =
    let* needs_install_admin =
      Component_registry.eval reg ~f:(fun cfg ->
          let module Cfg = (val cfg : Component_config) in
          Result.ok @@ Cfg.needs_install_admin ())
    in
    Result.ok (List.exists Fun.id needs_install_admin)
  in
  match at_least_one_component_needs_admin with
  | Ok v -> v
  | Error msg -> raise (Installation_error msg)

type static_files_source = Opam_context_static | Static_files_dir of string

(** [absdir_static_files ~component_name static_files_source] is
    the [component_name] component's static-files directory *)
let absdir_static_files ~component_name = function
  | Opam_context_static ->
      Runner.Os_utils.absdir_install_files ~component_name Static Opam_context
  | Static_files_dir static_files ->
      Runner.Os_utils.absdir_install_files ~component_name Static
        (Install_files_dir static_files)

(* Create command line options for dkml-install-{user,admin}-runner.exe *)

let z s = "--" ^ s

let runner_args ~log_config:{ log_config_style_renderer; log_config_level }
    ~prefix ~staging_files_source =
  let open Runner.Os_utils in
  let color =
    match log_config_style_renderer with
    | None -> "auto"
    | Some `None -> "never"
    | Some `Ansi_tty -> "always"
  in
  let args =
    Cmd.(
      empty
      % ("--verbosity=" ^ Logs.level_to_string log_config_level)
      % ("--color=" ^ color) % z prefix_arg % normalize_path prefix)
  in
  let args =
    match staging_files_source with
    | Runner.Path_eval.Global_context.Opam_context ->
        Cmd.(args % z opam_context_args)
    | Staging_files_dir staging_files ->
        Cmd.(args % z staging_files_arg % normalize_path staging_files)
  in
  args

let spawn cmd =
  Logs.info (fun m -> m "Running: %a" Cmd.pp cmd);
  Rresult.R.kignore_error ~use:(fun e ->
      let msg =
        Fmt.str "@[Failed to run:@,@[%s@]@]@,@[%a@]" (Cmd.to_string cmd)
          Rresult.R.pp_msg e
      in
      if Runner.Error_handling.errors_are_immediate () then
        raise (Runner.Error_handling.Installation_error msg)
      else Result.error msg)
  @@ (OS.Cmd.(run_status cmd) >>= function
      | `Exited 0 -> Result.ok ()
      | `Exited v ->
          Rresult.R.error_msgf "Exited with exit code %d: %a" v Cmd.pp cmd
      | `Signaled v ->
          Rresult.R.error_msgf "Signaled with signal %d: %a" v Cmd.pp cmd)

let elevated_cmd cmd =
  if Sys.win32 then
    (* dkml-install-admin-runner.exe on Win32 has a UAC manifest injected
       by link.exe in dune *)
    cmd
  else
    match OS.Cmd.find_tool (Cmd.v "doas") with
    | Ok (Some fpath) -> Cmd.(v (Fpath.to_string fpath) %% cmd)
    | Ok None | Error _ -> (
        match OS.Cmd.find_tool (Cmd.v "sudo") with
        | Ok (Some fpath) -> Cmd.(v (Fpath.to_string fpath) %% cmd)
        | Ok None | Error _ ->
            let su =
              (* raise (Installation_error msg) *)
              (* Rresult.R.failwith_error_msg ( *)
              match OS.Cmd.resolve (Cmd.v "su") with
              | Ok v -> v
              | Error e ->
                  raise
                    (Installation_error
                       (Fmt.str "@[Could not escalate to a superuser:@]@ @[%a@]"
                          Rresult.R.pp_msg e))
            in

            (* su -c "dkml-install-admin-runner ..." *)
            Cmd.(su % "-c" % to_string cmd))

let name_t =
  let doc = "The name of the program to install" in
  Arg.(required & opt (some string) None & info [ "name" ] ~doc)

(* Entry point of CLI *)
let setup log_config name prefix static_files staging_files opam_context =
  (* The Opam context staging file directory takes priority over
     any staging_files from the command line. *)
  let staging_files_source =
    Runner.Cmdliner_runner.staging_files_source ~opam_context
      ~staging_files_opt:(Some staging_files)
  in
  let static_files_source =
    if opam_context then Opam_context_static else Static_files_dir static_files
  in
  let args = runner_args ~log_config ~prefix ~staging_files_source in

  let exe_cmd s = Cmd.v Fpath.(to_string @@ (archive_dir_for_setup / s)) in

  let prefix_fp = Runner.Os_utils.string_to_norm_fpath prefix in
  let spawn_admin_if_needed () =
    if needs_install_admin then
      let+ (_ : unit list) =
        Component_registry.eval reg ~f:(fun cfg ->
            let module Cfg = (val cfg : Component_config) in
            spawn
            @@ elevated_cmd
                 Cmd.(
                   exe_cmd "dkml-install-admin-runner.exe"
                   % ("install-admin-" ^ Cfg.component_name)
                   %% args))
      in
      ()
    else Result.ok ()
  in
  let install_sequence =
    (* Run admin-runner.exe commands *)
    let* () = spawn_admin_if_needed () in
    (* Copy <static>/<component> into <prefix>, if present *)
    let* (_ : unit list) =
      Component_registry.eval reg ~f:(fun cfg ->
          let module Cfg = (val cfg : Component_config) in
          let* static_dir_fp =
            map_msg_error_to_string @@ Fpath.of_string
            @@ absdir_static_files ~component_name:Cfg.component_name
                 static_files_source
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
      Component_registry.eval reg ~f:(fun cfg ->
          let module Cfg = (val cfg : Component_config) in
          spawn
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
  let doc = "the OCaml CLI installer" in
  ( Term.(
      const setup $ setup_log_t $ name_t $ prefix_t $ static_files_for_setup_t
      $ staging_files_for_setup_t $ opam_context_t),
    Term.info "dkml-install-setup" ~version:"%%VERSION%%" ~doc )

let () =
  Term.(
    exit
    @@ catch_cmdliner_eval (fun () -> eval ~catch:false setup_cmd) (`Error `Exn))
