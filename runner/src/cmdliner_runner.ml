open Cmdliner

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
  ()

let setup_log_t =
  Term.(const setup_log $ Fmt_cli.style_renderer () $ Logs_cli.level ())

(* Define a context that includes all component-based fields *)

let create_context self_component_name reg () prefix staging_files_opt
    opam_context =
  let open Path_eval in
  let staging_files_source =
    match (opam_context, staging_files_opt) with
    | false, None ->
        failwith
          "Either `--opam-context` or `--staging-files DIR` must be specified"
    | true, _ -> Global_context.Opam_context
    | false, Some staging_files -> Staging_files_dir staging_files
  in
  let global_context = Global_context.create reg ~staging_files_source in
  let interpreter =
    Interpreter.create global_context ~self_component_name ~prefix
  in
  {
    Dkml_install_api.Context.eval = Interpreter.eval interpreter;
    path_eval = Interpreter.path_eval interpreter;
  }

(* Options for installation commands *)

let prefix_t =
  let doc = "$(docv) is the installation directory" in
  Arg.(
    required & opt (some string) None & info [ "prefix" ] ~docv:"PREFIX" ~doc)

let staging_files_opt_t =
  let doc = "$(docv) is the staging files directory for the installation" in
  Arg.(value & opt (some dir) None & info [ "staging-files" ] ~docv:"DIR" ~doc)

let opam_context_t =
  let doc =
    "Obtain staging files from the currently activated Opam switch defined by \
     the OPAM_SWITCH_PREFIX environment variable. A command like `(& opam env) \
     -split '\\r?\\n' | ForEach-Object { Invoke-Expression $$_ }` for Windows \
     PowerShell or `eval $$(opam env)` is necessary to activate an Opam switch \
     and set the OPAM_SWITCH_PREFIX environment variable"
  in
  Arg.(value & flag & info [ "opam-context" ] ~doc)

(** [ctx_t component] creates a [Term] for [component] that sets up logging
    and any other global state, and defines the context record *)
let ctx_t component_name reg =
  Term.(
    const create_context $ const component_name $ const reg $ setup_log_t
    $ prefix_t $ staging_files_opt_t $ opam_context_t)

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
