open Bos
open Cmdliner
open Dkml_install_register
open Dkml_install_api
module StringMap = Map.Make (String)

let ( >>= ) = Result.bind

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

(* Commands *)

let help_cmd =
  let topic =
    let doc = "The topic to get help on. `topics' lists the topics." in
    Arg.(value & pos 0 (some string) None & info [] ~docv:"TOPIC" ~doc)
  in
  let doc =
    "display help about dkml-install-runner and dkml-install-runner commands"
  in
  let man =
    [
      `S Manpage.s_description;
      `P "Prints help about dkml-install-runner commands and other subjects...";
      `Blocks help_secs;
    ]
  in
  ( Term.(ret (const help $ Arg.man_format $ Term.choice_names $ topic)),
    Term.info "help" ~doc ~exits:Term.default_exits ~man )

let default_cmd =
  let doc = "the OCaml CLI installer" in
  let sdocs = Manpage.s_common_options in
  let exits = Term.default_exits in
  let man = help_secs in
  ( Term.(ret (const (fun () -> `Help (`Pager, None)) $ setup_log_t)),
    Term.info "dkml-install-runner" ~version:"%%VERSION%%" ~doc ~sdocs ~exits
      ~man )

let cmds = [ help_cmd ]

(* Load dkml-install-api module so that Dynlink access control
   does not prohibit plugins (components) from loading it by
   raising a Dynlink.Unavailable_unit error.

   Confer:
   https://ocaml.org/api/Dynlink.html#1_Accesscontrol "set_allowed_units" *)
let (_ : string list) = Default_component_config.depends_on

(* Load all the available components *)
let () = Sites.Plugins.Plugins.load_all ()

let reg = Component_registry.get ()

(* Define a context that includes all component-based fields *)

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

(** [string_to_fpath str] converts [str] into a [Fpath.t]. On Windows the
    [str] is normalized to a regular Windows file path (ex. backslashes). *)
let string_to_norm_fpath str =
  match Fpath.of_string str with Ok p -> p | Error (`Msg e) -> failwith e

(** [absdir_staging_files ~component_name ~opam_context ~staging_files_opt] is
    the [component_name] component's staging-files directory *)
let absdir_staging_files ~component_name ~opam_context ~staging_files_opt =
  match (opam_context, staging_files_opt) with
  | false, None ->
      failwith
        "Either `--opam-context` or `--staging-files DIR` must be specified"
  | true, _ ->
      let opam_switch_prefix = OS.Env.opt_var "OPAM_SWITCH_PREFIX" ~absent:"" in
      if opam_switch_prefix = "" then
        failwith
          "When using --opam-context the OPAM_SWITCH_PREFIX environment \
           variable must be defined by evaluating the `opam env` command.";
      Fpath.(
        to_string
        @@ string_to_norm_fpath opam_switch_prefix
           / "share"
           / ("dkml-component-" ^ component_name)
           / "staging-files")
  | false, Some staging_files ->
      Fpath.(to_string @@ (string_to_norm_fpath staging_files / component_name))

let create_context self_component_name () prefix staging_files_opt opam_context
    =
  let share_vars_res =
    Component_registry.eval reg ~f:(fun cfg ->
        let module Cfg = (val cfg : Component_config) in
        Result.ok
          ( Cfg.component_name ^ ":share",
            absdir_staging_files ~component_name:Cfg.component_name
              ~opam_context ~staging_files_opt ))
  in
  let share_vars =
    match share_vars_res with
    | Ok var_list -> var_list
    | Error err -> failwith err
  in
  let name_var = ("name", self_component_name) in
  let temp_var =
    ( "tmp",
      Fpath.to_string @@ Rresult.R.error_msg_to_invalid_arg @@ OS.Dir.tmp "%s"
    )
  in
  let prefix_var = ("prefix", Fpath.to_string @@ string_to_norm_fpath prefix) in
  let all_vars_mp =
    List.concat [ share_vars; [ name_var; temp_var; prefix_var ] ]
    |> List.to_seq |> StringMap.of_seq
  in
  let path_eval expression =
    let rec eval text = function
      | [] -> text
      | (varname, varvalue) :: tl ->
          let search_for = "%{" ^ varname ^ "}%" in
          let new_text =
            Str.(global_replace (regexp_string search_for) varvalue text)
          in
          eval new_text tl
    in
    eval expression (StringMap.to_seq all_vars_mp |> List.of_seq)
  in
  { Dkml_install_api.Context.path_eval }

(** [ctx_t component] creates a [Term] for [component] that sets up logging
    and any other global state, and defines the context record *)
let ctx_t component_name =
  Term.(
    const create_context $ const component_name $ setup_log_t $ prefix_t
    $ staging_files_opt_t $ opam_context_t)

(* Install all CLI subcommands for all the components *)
let component_cmds =
  let cmd_results =
    Component_registry.eval reg ~f:(fun cfg ->
        let module Cfg = (val cfg : Component_config) in
        Cfg.install_user_subcommand ~component_name:Cfg.component_name
          ~subcommand_name:(Fmt.str "install-user-%s" Cfg.component_name)
          ~ctx_t:(ctx_t Cfg.component_name))
    >>= fun install_user_cmds ->
    Component_registry.eval reg ~f:(fun cfg ->
        let module Cfg = (val cfg : Component_config) in
        Cfg.uninstall_user_subcommand ~component_name:Cfg.component_name
          ~subcommand_name:(Fmt.str "uninstall-user-%s" Cfg.component_name)
          ~ctx_t:(ctx_t Cfg.component_name))
    >>= fun uninstall_user_cmds ->
    Component_registry.eval reg ~f:(fun cfg ->
        let module Cfg = (val cfg : Component_config) in
        Cfg.install_admin_subcommand ~component_name:Cfg.component_name
          ~subcommand_name:(Fmt.str "install-admin-%s" Cfg.component_name)
          ~ctx_t:(ctx_t Cfg.component_name))
    >>= fun install_admin_cmds ->
    Component_registry.eval reg ~f:(fun cfg ->
        let module Cfg = (val cfg : Component_config) in
        Cfg.uninstall_admin_subcommand ~component_name:Cfg.component_name
          ~subcommand_name:(Fmt.str "uninstall-admin-%s" Cfg.component_name)
          ~ctx_t:(ctx_t Cfg.component_name))
    >>= fun uninstall_admin_cmds ->
    Result.ok
      (install_user_cmds @ uninstall_user_cmds @ install_admin_cmds
     @ uninstall_admin_cmds)
  in
  match cmd_results with Ok cmds -> cmds | Error msg -> failwith msg

let () = Term.(exit @@ eval_choice default_cmd (help_cmd :: component_cmds))
