open Cmdliner
open Bos

let help man_format cmds topic =
  match topic with
  | None -> `Help (`Pager, None) (* help about the program. *)
  | Some topic -> (
      let topics = "topics" :: cmds in
      let conv, _ = Cmdliner.Arg.enum (List.rev_map (fun s -> (s, s)) topics) in
      match conv topic with
      | `Error e -> `Error (false, e)
      | `Ok t when t = "topics" ->
          List.iter print_endline topics;
          `Ok ()
      | `Ok t when List.mem t cmds -> `Help (man_format, Some t)
      | `Ok _t ->
          (* should never get here if all `topics` are handled *)
          `Help (`Pager, None))

(* Help sections common to all commands *)

let help_secs =
  [
    `S Manpage.s_common_options;
    `P "These options are common to all commands.";
    `S "MORE HELP";
    `P "Use $(mname) $(i,COMMAND) --help for help on a single command.";
  ]

(* Options common to all commands *)

let setup_log style_renderer level =
  Fmt_tty.setup_std_outputs ?style_renderer ();
  Logs.set_level level;
  Logs.set_reporter (Logs_fmt.reporter ());
  Dkml_install_api.Log_config.create ?log_config_style_renderer:style_renderer
    ?log_config_level:level ()

let setup_log_t =
  Term.(const setup_log $ Fmt_cli.style_renderer () $ Logs_cli.level ())

(* Define a context that includes all component-based fields *)

let create_context ~staging_default ~target_abi self_component_name reg
    log_config prefix staging_files_opt opam_context_opt =
  let open Path_eval in
  let open Error_handling.Monad_syntax in
  let* staging_files_source, _fl =
    Path_location.staging_files_source ~staging_default ~opam_context_opt
      ~staging_files_opt
  in
  let* global_context, _fl = Global_context.create reg in
  let* interpreter, _fl =
    Interpreter.create global_context ~self_component_name ~abi:target_abi
      ~staging_files_source ~prefix:(Fpath.v prefix)
  in
  return
    {
      Dkml_install_api.Context.eval = Interpreter.eval interpreter;
      path_eval = Interpreter.path_eval interpreter;
      target_abi_v2 = target_abi;
      log_config;
    }

(* Cmdliner, at least in 1.0.4, has the pp_str treated as an escaped OCaml
   string. Not sure why, but backslashes on Windows path are interpreted
   to be escape sequences. So create raw_* to add escaping to the raw
   strings. *)

let quote s = Fmt.str "`%s'" s

let err_no kind s = Fmt.str "no %s %s" (quote s) kind

let err_not_dir s = Fmt.str "%s is not a directory" (quote s)

let raw_pp_str fmt s = Fmt.string fmt (String.escaped s)

let raw_dir =
  let parse s =
    match Sys.file_exists s with
    | true -> if Sys.is_directory s then `Ok s else `Error (err_not_dir s)
    | false -> `Error (err_no "directory" s)
  in
  (parse, raw_pp_str)

(* Options for installation commands *)

let prefix_t =
  let doc = "$(docv) is the installation directory" in
  Arg.(
    required
    & opt (some string) None
    & info [ Cmdliner_common.prefix_arg ] ~docv:"PREFIX" ~doc)

(** Directory containing dkml-package-setup.bc or whatever executable
   (perhaps a renamed setup.exe in a non-bin folder) is currently running. *)
let exec_dir = Fpath.(parent (v OS.Arg.exec))

(** The root directory that was uncompressed at end-user install time *)
let enduser_archive_dir () =
  (* get path to .archivetree *)
  let open Error_handling.Monad_syntax in
  let archivetree () =
    Diskuvbox.find_up ~from_dir:exec_dir ~basenames:[ Fpath.v ".archivetree" ]
      ~max_ascent:3 ()
  in
  let* archivetree_opt, fl =
    Dkml_install_api.Forward_progress.lift_result __POS__ Fmt.lines
      Error_handling.runner_fatal_log (archivetree ())
  in
  match archivetree_opt with
  | Some archivetree ->
      (* the archive directory is the directory containing .archivetree *)
      return (fst (Fpath.split_base archivetree))
  | None ->
      fl ~id:"855c1e64"
        (Fmt.str
           "The archive directory containing .archivetree could not be located \
            in %a or an ancestor"
           Fpath.pp exec_dir);
      Dkml_install_api.Forward_progress.Halted_progress Exit_transient_failure

(** [staging_default_dir_for_package ~archive_dir].
    For the benefit of Windows and macOS we keep the directory name ("sg") small. *)
let staging_default_dir_for_package ~archive_dir = Fpath.(archive_dir / "sg")

(** [static_default_dir_for_package ~archive_dir].
    For the benefit of Windows and macOS we keep the directory name ("st") small. *)
let static_default_dir_for_package ~archive_dir = Fpath.(archive_dir / "st")

let staging_files_opt_t =
  let doc = "$(docv) is the staging files directory for the installation" in
  Arg.(
    value
    & opt (some raw_dir) None
    & info [ Cmdliner_common.staging_files_arg ] ~docv:"DIR" ~doc)

let static_files_opt_t =
  let doc = "$(docv) is the static files directory of the installation" in
  Arg.(
    value
    & opt (some raw_dir) None
    & info [ Cmdliner_common.static_files_arg ] ~docv:"DIR" ~doc)

let opam_context_opt_t =
  let doc =
    Fmt.str
      "Obtain staging files from an Opam switch. Ignored if $(b,--%s) \
       specified. The Opam switch prefix can be unspecified which indicates to \
       use the Opam default switch (if any) or the Opam switch prefix can be \
       specified as an option argument. 1) A switch prefix is either the \
       $(b,_opam) subdirectory of a local Opam switch or $(b,%s/<switchname>) \
       for a global Opam switch. 2) The default Opam switch is the currently \
       activated Opam switch defined by the OPAM_SWITCH_PREFIX environment \
       variable; the OPAM_SWITCH_PREFIX environment variable is set \
       automatically by commands like `%s`."
      Cmdliner_common.staging_files_arg
      (Manpage.escape "$OPAMROOT")
      (Manpage.escape
         "(& opam env) -split '\\r?\\n' | ForEach-Object { Invoke-Expression \
          $_ }` for Windows PowerShell or `eval $(opam env)")
  in
  let opt_escaped = function
    | None -> None
    | Some s -> Some (Manpage.escape s)
  in
  Arg.(
    value
    & opt ~vopt:(opt_escaped (OS.Env.var "OPAM_SWITCH_PREFIX")) (some dir) None
    & info [ Cmdliner_common.opam_context_args ] ~docv:"OPAM_SWITCH_PREFIX" ~doc)

(** [staging_files_source_for_package_t] is the
    setup.exe/uninstall.exe {!Term.t} for the staging files directory.  It
    defaults to the sibling directory "staging". *)
let staging_files_source_for_package_t =
  let staging_files_source' opam_context_opt staging_files_opt =
    let staging_default =
      Path_location.Staging_default_dir
        (fun () ->
          staging_default_dir_for_package
            ~archive_dir:
              (Error_handling.continue_or_exit @@ enduser_archive_dir ()))
    in
    Path_location.staging_files_source ~staging_default ~opam_context_opt
      ~staging_files_opt
  in
  Term.(const staging_files_source' $ opam_context_opt_t $ staging_files_opt_t)

(** [static_files_source_for_package_t] is the
    setup.exe/uninstall.exe {!Term.t} for the static files directory.  It
    defaults to the sibling directory "static". *)
let static_files_source_for_package_t =
  let static_files_source' opam_context_opt static_files_opt =
    let static_default =
      Path_location.Static_default_dir
        (fun () ->
          static_default_dir_for_package
            ~archive_dir:
              (Error_handling.continue_or_exit @@ enduser_archive_dir ()))
    in
    Path_location.static_files_source ~static_default ~opam_context_opt
      ~static_files_opt
  in
  Term.(const static_files_source' $ opam_context_opt_t $ static_files_opt_t)

let unwrap_progress_t ~default t =
  let unwrap = function
    | Dkml_install_api.Forward_progress.Completed -> default
    | Dkml_install_api.Forward_progress.Continue_progress (a, _fl) -> a
    | Dkml_install_api.Forward_progress.Halted_progress exitcode ->
        exit
          (Dkml_install_api.Forward_progress.Exit_code.to_int_exitcode exitcode)
  in
  Term.(const unwrap $ t)

let unwrap_progress_nodefault_t t =
  let unwrap = function
    | Dkml_install_api.Forward_progress.Completed ->
        raise (Invalid_argument "Completed forward progress was not expected")
    | Dkml_install_api.Forward_progress.Continue_progress (a, _fl) -> a
    | Dkml_install_api.Forward_progress.Halted_progress exitcode ->
        exit
          (Dkml_install_api.Forward_progress.Exit_code.to_int_exitcode exitcode)
  in
  Term.(const unwrap $ t)

(** [ctx_for_runner_t component_name reg] creates a user.exe/admin.exe [Term]
    for component [component_name]
    that sets up logging and any other global state, and defines the context
    record.
    
    The package (setup.exe/uninstall.exe) will typically use sudo on Unix
    or gsudo on Windows to elevate the privileges of `admin.exe`. However
    it is very unlikely that the environment variables are propagated from
    the user (setup.exe) to the elevated process (admin.exe). So the
    staging directory must be specified (`No_staging_default`) when the runner
    user.exe/admin.exe is launched.
    
    That is, the user process setup.exe can pass its
    environment variable OPAM_SWITCH_PREFIX (if specified with the no argument
    `--opam-context` option of setup.exe) into the staging directory argument
    for admin.exe. *)
let ctx_for_runner_t ~target_abi component_name reg =
  let t =
    Term.(
      const (create_context ~target_abi ~staging_default:No_staging_default)
      $ const component_name $ const reg $ setup_log_t $ prefix_t
      $ staging_files_opt_t $ opam_context_opt_t)
  in
  unwrap_progress_nodefault_t t

(** [ctx_for_package_t component_name reg] creates a setup.exe/uninstall.exe [Term]
    for component [component_name] that sets up logging and any other global
    state, and defines the context record.
    
    Unlike {!ctx_for_runner_t} the expectation is that setup.exe/uninstall.exe
    will be directly launched by the user and have access to the user's
    environment variables, especially OPAM_SWITCH_PREFIX. So the no argument
    --opam-context option of setup.exe can default to OPAM_SWITCH_PREFIX.

    Unlike {!ctx_for_runner_t} the staging directory has a default
    (`Staging_default_dir`) based on relative paths from setup.exe. *)
let ctx_for_package_t ~target_abi component_name reg =
  let staging_default =
    Path_location.Staging_default_dir
      (fun () ->
        staging_default_dir_for_package
          ~archive_dir:
            (Error_handling.continue_or_exit @@ enduser_archive_dir ()))
  in
  let t =
    Term.(
      const (create_context ~target_abi ~staging_default)
      $ const component_name $ const reg $ setup_log_t $ prefix_t
      $ staging_files_opt_t $ opam_context_opt_t)
  in
  unwrap_progress_nodefault_t t

let to_selector component_selector =
  if component_selector = [] then
    Dkml_install_register.Component_registry.All_components
  else Just_named_components_plus_their_dependencies component_selector

let component_selector_t ~install =
  let doc =
    if install then
      "A component to install; all the components it depends on are implicitly \
       added. May be repeated. If no components are specified, then all \
       components are installed."
    else
      "A component to uninstall; all the components it depends on are \
       implicitly added. May be repeated. If no components are specified, then \
       all components are uninstalled."
  in
  Arg.(value & opt_all string [] & info [ "component" ] ~doc)

(* Misc *)

let common_runner_args ~log_config ~prefix ~staging_files_source =
  let z s = "--" ^ s in
  let args =
    Cmd.(
      Dkml_install_api.Log_config.to_args log_config
      % z Cmdliner_common.prefix_arg
      % Fpath.to_string prefix)
  in
  let args =
    match staging_files_source with
    | Path_location.Opam_staging_switch_prefix switch_prefix ->
        Cmd.(
          args
          % z Cmdliner_common.opam_context_args
          % Fpath.to_string switch_prefix)
    | Staging_files_dir staging_files ->
        Cmd.(
          args
          % z Cmdliner_common.staging_files_arg
          % Fpath.to_string staging_files)
  in
  args

(* Commands *)

let help_cmd =
  let topic =
    let doc = "The topic to get help on. `topics' lists the topics." in
    Arg.(value & pos 0 (some string) None & info [] ~docv:"TOPIC" ~doc)
  in
  let doc = "display help about $(mname) and $(mname) commands" in
  let man =
    [
      `S Manpage.s_description;
      `P "Prints help about $(mname) commands and other subjects...";
      `Blocks help_secs;
    ]
  in
  ( Term.(ret (const help $ Arg.man_format $ Term.choice_names $ topic)),
    Term.info "help" ~doc ~exits:Term.default_exits ~man )

(* Term evalation *)

let eval_progress (term, info) =
  match Term.eval (term, info) with
  | `Ok v -> (
      match v with
      | Dkml_install_api.Forward_progress.Completed -> `Ok ()
      | Dkml_install_api.Forward_progress.Continue_progress _ -> `Ok ()
      | Dkml_install_api.Forward_progress.Halted_progress exitcode ->
          exit
            (Dkml_install_api.Forward_progress.Exit_code.to_int_exitcode
               exitcode))
  | `Version -> `Version
  | `Help -> `Help
  | `Error e -> `Error e
