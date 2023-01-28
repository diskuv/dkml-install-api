open Bos
open Astring
open Dkml_install_api
open Dkml_install_runner.Error_handling.Monad_syntax
include Error_utils

(* Pull in other modules and functions to fill out .mli *)
(* BEGIN *)
module Author_types = Author_types
module Windows_registry = Windows_registry

let spawn = Spawn.spawn
(* END *)

open Author_types

(** [parse_version] parses ["[v|V]major.minor[.patch][(+|-)info]"].
    Verbatim from https://erratique.ch/software/astring/doc/Astring/index.html

    We are not using semver2 Opam package because it has bigstringaf DLL stublibs. *)
let parse_version : string -> (int * int * int * string option) option =
 fun s ->
  try
    let parse_opt_v s =
      match String.Sub.head s with
      | Some ('v' | 'V') -> String.Sub.tail s
      | Some _ -> s
      | None -> raise Exit
    in
    let parse_dot s =
      match String.Sub.head s with
      | Some '.' -> String.Sub.tail s
      | Some _ | None -> raise Exit
    in
    let parse_int s =
      match String.Sub.span ~min:1 ~sat:Char.Ascii.is_digit s with
      | i, _ when String.Sub.is_empty i -> raise Exit
      | i, s -> (
          match String.Sub.to_int i with None -> raise Exit | Some i -> (i, s))
    in
    let maj, s = parse_int (parse_opt_v (String.sub s)) in
    let min, s = parse_int (parse_dot s) in
    let patch, s =
      match String.Sub.head s with
      | Some '.' -> parse_int (parse_dot s)
      | _ -> (0, s)
    in
    let info =
      match String.Sub.head s with
      | Some ('+' | '-') -> Some String.Sub.(to_string (tail s))
      | Some _ -> raise Exit
      | None -> None
    in
    Some (maj, min, patch, info)
  with Exit -> None

(** [ver_m_n_o_p ver] converts the version [ver] into the
    ["mmmmm.nnnnn.ooooo.ppppp"] format required by an Application Manifest.

    Confer https://docs.microsoft.com/en-us/windows/win32/sbscs/application-manifests#assemblyidentity *)
let version_m_n_o_p version =
  match parse_version version with
  | Some (major, minor, patch, _info) -> Fmt.str "%d.%d.%d.0" major minor patch
  | None -> "0.0.0.0"

let create_minimal_context ~self_component_name ~log_config ~target_abi ~prefix
    ~staging_files_source =
  let open Dkml_install_runner.Path_eval in
  let* interpreter, _fl =
    Interpreter.create_minimal ~self_component_name ~abi:target_abi
      ~staging_files_source ~prefix
  in
  return
    {
      Context.eval = Interpreter.eval interpreter;
      path_eval = Interpreter.path_eval interpreter;
      target_abi_v2 = target_abi;
      log_config;
    }

let needs_install_admin ~reg ~selector ~log_config ~target_abi ~prefix
    ~staging_files_source =
  let+ bools =
    Dkml_install_register.Component_registry.install_eval reg ~selector
      ~fl:Dkml_install_runner.Error_handling.runner_fatal_log ~f:(fun cfg ->
        let module Cfg = (val cfg : Component_config) in
        let* ctx, _fl =
          create_minimal_context ~self_component_name:Cfg.component_name
            ~log_config ~target_abi ~prefix ~staging_files_source
        in
        Logs.debug (fun l ->
            l
              "Checking if we need to request administrator privileges for %s \
               ..."
              Cfg.component_name);
        let ret = Cfg.needs_install_admin ~ctx in
        Logs.debug (fun l ->
            l "Administrator required to install %s? %b" Cfg.component_name ret);
        return ret)
  in
  List.exists Fun.id bools

let needs_uninstall_admin ~reg ~selector ~log_config ~target_abi ~prefix
    ~staging_files_source =
  let+ bools =
    Dkml_install_register.Component_registry.uninstall_eval reg ~selector
      ~fl:Dkml_install_runner.Error_handling.runner_fatal_log ~f:(fun cfg ->
        let module Cfg = (val cfg : Component_config) in
        let* ctx, _fl =
          create_minimal_context ~self_component_name:Cfg.component_name
            ~log_config ~target_abi ~prefix ~staging_files_source
        in
        Logs.debug (fun l ->
            l
              "Checking if we need to request administrator privileges for %s \
               ..."
              Cfg.component_name);
        let ret = Cfg.needs_uninstall_admin ~ctx in
        Logs.debug (fun l ->
            l "Administrator required to uninstall %s? %b" Cfg.component_name
              ret);
        return ret)
  in
  List.exists Fun.id bools

let console_component_name = "xx-console"
let console_required_components = [ console_component_name; "staging-ocamlrun" ]

let elevated_cmd ~target_abi ~staging_files_source cmd =
  if Context.Abi_v2.is_windows target_abi then
    (* dkml-install-admin.exe on Win32 has a UAC manifest injected
       by link.exe in dune. But still will get
       "The requested operation requires elevation" if dkml-install-admin.exe
       is spawned from another process rather than directly from
       Command Prompt or PowerShell.
       So use `gsudo` from dkml-package-console. *)
    let component_dir =
      Dkml_install_runner.Path_location.absdir_staging_files
        ~package_selector:Package ~component_name:console_component_name
        ~abi_selector:(Abi target_abi) staging_files_source
    in
    let gsudo = Fpath.(component_dir / "bin" / "gsudo.exe") in
    match Logs.level () with
    | Some Debug ->
        return
          Cmd.(
            v (Fpath.to_string gsudo) % "--wait" % "--direct" % "--debug" %% cmd)
    | Some _ | None ->
        return Cmd.(v (Fpath.to_string gsudo) % "--wait" % "--direct" %% cmd)
  else
    match OS.Cmd.find_tool (Cmd.v "doas") with
    | Ok (Some fpath) -> return Cmd.(v (Fpath.to_string fpath) %% cmd)
    | Ok None | Error _ -> (
        match OS.Cmd.find_tool (Cmd.v "sudo") with
        | Ok (Some fpath) -> return Cmd.(v (Fpath.to_string fpath) %% cmd)
        | Ok None | Error _ -> (
            match OS.Cmd.resolve (Cmd.v "su") with
            | Ok su ->
                (* su -c "<package>-admin-runner ..." *)
                return Cmd.(su % "-c" % to_string cmd)
            | Error e ->
                Dkml_install_runner.Error_handling.runner_fatal_log
                  ~id:"6320d6e4"
                  (Fmt.str "@[Could not escalate to a superuser:@]@ @[%a@]"
                     Rresult.R.pp_msg e);
                Forward_progress.(Halted_progress Exit_transient_failure)))

let home_dir_fp () =
  let open Dkml_install_runner.Error_handling in
  let* home_str, _fl = map_rresult_error_to_progress @@ OS.Env.req_var "HOME" in
  let* home_fp, _fl =
    map_rresult_error_to_progress @@ Fpath.of_string home_str
  in
  (* ensure HOME is a pre-existing directory *)
  map_rresult_error_to_progress @@ OS.Dir.must_exist home_fp

let get_default_user_installation_prefix_windows
    ~installation_prefix_camel_case_nospaces =
  let open Dkml_install_runner.Error_handling in
  let* local_app_data_str, _fl =
    map_rresult_error_to_progress @@ OS.Env.req_var "LOCALAPPDATA"
  in
  let* local_app_data_fp, _fl =
    map_rresult_error_to_progress @@ Fpath.of_string local_app_data_str
  in
  (* ensure LOCALAPPDATA is a pre-existing directory *)
  let* local_app_data_fp, _fl =
    map_rresult_error_to_progress @@ OS.Dir.must_exist local_app_data_fp
  in
  return
    Fpath.(
      local_app_data_fp / "Programs" / installation_prefix_camel_case_nospaces)

let get_default_user_installation_prefix_darwin
    ~installation_prefix_camel_case_nospaces =
  let* home_dir_fp, _fl = home_dir_fp () in
  return
    Fpath.(
      home_dir_fp / "Applications" / installation_prefix_camel_case_nospaces)

let get_default_user_installation_prefix_linux
    ~installation_prefix_kebab_lower_case =
  let open Dkml_install_runner.Error_handling in
  match OS.Env.var "XDG_DATA_HOME" with
  | Some xdg_data_home ->
      let* fp, _fl =
        map_rresult_error_to_progress @@ Fpath.of_string xdg_data_home
      in
      return Fpath.(fp / installation_prefix_kebab_lower_case)
  | None ->
      let* home_dir_fp, _fl = home_dir_fp () in
      return
        Fpath.(
          home_dir_fp / ".local" / "share"
          / installation_prefix_kebab_lower_case)

let get_user_installation_prefix ~program_name ~target_abi ~prefix_opt =
  let installation_prefix_camel_case_nospaces =
    match program_name.installation_prefix_camel_case_nospaces_opt with
    | Some v -> v
    | None -> program_name.name_camel_case_nospaces
  in
  let installation_prefix_kebab_lower_case =
    match program_name.installation_prefix_kebab_lower_case_opt with
    | Some v -> v
    | None -> program_name.name_kebab_lower_case
  in
  match prefix_opt with
  | Some prefix -> return (Fpath.v prefix)
  | None ->
      if Context.Abi_v2.is_windows target_abi then
        get_default_user_installation_prefix_windows
          ~installation_prefix_camel_case_nospaces
      else if Context.Abi_v2.is_darwin target_abi then
        get_default_user_installation_prefix_darwin
          ~installation_prefix_camel_case_nospaces
      else if Context.Abi_v2.is_linux target_abi then
        get_default_user_installation_prefix_linux
          ~installation_prefix_kebab_lower_case
      else (
        Dkml_install_runner.Error_handling.runner_fatal_log ~id:"14420023"
          (Fmt.str
             "No rules defined for the default user installation prefix of the \
              ABI %a"
             Context.Abi_v2.pp target_abi);
        Forward_progress.(Halted_progress Exit_unrecoverable_failure))

(* Command Line Processing *)

type package_args = {
  log_config : Log_config.t;
  prefix_opt : string option;
  component_selector : string list;
  static_files_source : Dkml_install_runner.Path_location.static_files_source;
  staging_files_source : Dkml_install_runner.Path_location.staging_files_source;
}

let prefix_opt_t ~program_name ~target_abi =
  let doc =
    Fmt.str
      "$(docv) is the installation directory. If not set and $(b,--%s) is also \
       not set, then $(i,%s) will be used as the installation directory"
      Dkml_install_runner.Cmdliner_common.opam_context_args
      (Cmdliner.Manpage.escape
         (Fpath.to_string
            (Dkml_install_runner.Error_handling.continue_or_exit
            @@ get_user_installation_prefix ~program_name ~target_abi
                 ~prefix_opt:None)))
  in
  Cmdliner.Arg.(
    value
    & opt (some string) None
    & info
        [ Dkml_install_runner.Cmdliner_common.prefix_arg ]
        ~docv:"PREFIX" ~doc)

let package_args_t ~program_name ~target_abi ~install_direction =
  let package_args log_config prefix_opt component_selector static_files_source
      staging_files_source =
    {
      log_config;
      prefix_opt;
      component_selector;
      static_files_source =
        Dkml_install_runner.Error_handling.continue_or_exit static_files_source;
      staging_files_source =
        Dkml_install_runner.Error_handling.continue_or_exit staging_files_source;
    }
  in
  Cmdliner.Term.(
    const package_args $ Dkml_install_runner.Cmdliner_runner.setup_log_t
    $ prefix_opt_t ~program_name ~target_abi
    $ Dkml_install_runner.Cmdliner_runner.component_selector_t
        ~install_direction
    $ Dkml_install_runner.Cmdliner_runner.static_files_source_for_package_t
    $ Dkml_install_runner.Cmdliner_runner.staging_files_source_for_package_t)
