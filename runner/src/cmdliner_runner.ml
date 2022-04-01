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

let create_context self_component_name reg log_config prefix staging_files_opt
    opam_context_opt =
  let open Path_eval in
  let staging_files_source =
    Path_location.staging_files_source ~opam_context_opt ~staging_files_opt
  in
  let global_context = Global_context.create reg in
  let host_abi_v2 =
    match Host_abi.create_v2 () with
    | Ok abi -> abi
    | Error s ->
        raise
          (Dkml_install_api.Installation_error
             (Fmt.str "Could not detect the host ABI. %s" s))
  in
  let interpreter =
    Interpreter.create global_context ~self_component_name ~abi:host_abi_v2
      ~staging_files_source ~prefix
  in
  {
    Dkml_install_api.Context.eval = Interpreter.eval interpreter;
    path_eval = Interpreter.path_eval interpreter;
    host_abi_v2;
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

(* Directory containing dkml-install-setup.exe *)
let archive_dir_for_setup = Fpath.(v OS.Arg.exec |> parent)

let staging_files_opt_t =
  let doc =
    Fmt.str
      "$(docv) is the staging files directory for the installation. Takes \
       priority over $(b,--%s)"
      Cmdliner_common.opam_context_args
  in
  Arg.(
    value
    & opt (some raw_dir) None
    & info [ Cmdliner_common.staging_files_arg ] ~docv:"DIR" ~doc)

(** [staging_files_for_setup_and_uninstaller_t] is the dkml-install-setup.exe Term for the
    staging files directory.  It defaults to the sibling directory "staging". *)
let staging_files_for_setup_and_uninstaller_t =
  let default_dir = Fpath.(archive_dir_for_setup / "staging") in
  let doc =
    Fmt.str
      "$(docv) is the staging files directory of the installation. Takes \
       priority over $(b,--%s)"
      Cmdliner_common.opam_context_args
  in
  Arg.(
    value
    & opt raw_dir (Fpath.to_string default_dir)
    & info [ Cmdliner_common.staging_files_arg ] ~docv:"DIR" ~doc)

(** [static_files_for_setup_and_uninstaller_t] is the dkml-install-setup.exe Term for the
    static files directory.  It defaults to the sibling directory "static". *)
let static_files_for_setup_and_uninstaller_t =
  let default_dir = Fpath.(archive_dir_for_setup / "static") in
  let doc = "$(docv) is the static files directory of the installation" in
  Arg.(
    value
    & opt raw_dir (Fpath.to_string default_dir)
    & info [ Cmdliner_common.static_files_arg ] ~docv:"DIR" ~doc)

let opam_context_opt_t =
  let doc =
    Manpage.escape
      (Fmt.str
         "Obtain staging files from an Opam switch. Ignored if $(b,--%s) \
          specified. The Opam switch prefix can be unspecified which indicates \
          to use the Opam default switch (if any) or the Opam switch prefix \
          can be specified as an option argument. 1) A switch prefix is either \
          the {b _opam} subdirectory of a local Opam switch or {b \
          $OPAMROOT/<switchname>} for a global Opam switch. 2) The default \
          Opam switch is the currently activated Opam switch defined by the \
          OPAM_SWITCH_PREFIX environment variable; the OPAM_SWITCH_PREFIX \
          environment variable is set automatically by commands like `(& opam \
          env) -split '\\r?\\n' | ForEach-Object { Invoke-Expression $_ }` for \
          Windows PowerShell or `eval $(opam env)`."
         Cmdliner_common.staging_files_arg)
  in
  let hack_cmdliner_backslash = function
    | None -> None
    | Some s -> Some (String.map (function '\\' -> '/' | c -> c) s)
  in
  Arg.(
    value
    & opt
        ~vopt:(hack_cmdliner_backslash (OS.Env.var "OPAM_SWITCH_PREFIX"))
        (some dir) None
    & info [ Cmdliner_common.opam_context_args ] ~docv:"OPAM_SWITCH_PREFIX" ~doc)

let staging_files_source_for_setup_and_uninstaller_t =
  (* The Opam context staging file directory takes priority over
     any staging_files from the command line. *)
  let _staging_files_source opam_context_opt staging_files =
    Path_location.staging_files_source ~opam_context_opt
      ~staging_files_opt:(Some staging_files)
  in
  Term.(
    const _staging_files_source
    $ opam_context_opt_t $ staging_files_for_setup_and_uninstaller_t)

let static_files_source_for_setup_and_uninstaller_t =
  let static_files_source opam_context_opt static_files =
    match opam_context_opt with
    | Some switch_prefix ->
        Path_location.Opam_static_switch_prefix switch_prefix
    | None -> Static_files_dir static_files
  in
  Term.(
    const static_files_source $ opam_context_opt_t
    $ static_files_for_setup_and_uninstaller_t)

(** [ctx_t component_name reg] creates a [Term] for component [component_name]
    that sets up logging and any other global state, and defines the context
    record *)
let ctx_t component_name reg =
  Term.(
    const create_context $ const component_name $ const reg $ setup_log_t
    $ prefix_t $ staging_files_opt_t $ opam_context_opt_t)

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
  let open Os_utils in
  let z s = "--" ^ s in
  let args =
    Cmd.(
      Dkml_install_api.Log_config.to_args log_config
      % z Cmdliner_common.prefix_arg
      % normalize_path prefix)
  in
  let args =
    match staging_files_source with
    | Path_location.Opam_staging_switch_prefix switch_prefix ->
        Cmd.(
          args
          % z Cmdliner_common.opam_context_args
          % normalize_path switch_prefix)
    | Staging_files_dir staging_files ->
        Cmd.(
          args
          % z Cmdliner_common.staging_files_arg
          % normalize_path staging_files)
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
