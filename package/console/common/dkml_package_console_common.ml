open Bos
open Astring
open Dkml_install_api
include Error_utils

type program_name = {
  name_full : string;
  name_camel_case_nospaces : string;
  name_kebab_lower_case : string;
  installation_prefix_camel_case_nospaces_opt : string option;
  installation_prefix_kebab_lower_case_opt : string option;
}

type organization = {
  legal_name : string;
  common_name_full : string;
  common_name_camel_case_nospaces : string;
  common_name_kebab_lower_case : string;
}

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

(* let target_abi_v2 () =
   match Dkml_install_runner.Host_abi.create_v2 () with
   | Ok abi -> abi
   | Error s ->
       raise (Installation_error (Fmt.str "Could not detect the host ABI. %s" s)) *)

let create_minimal_context ~self_component_name ~log_config ~target_abi ~prefix
    ~staging_files_source =
  let open Dkml_install_runner.Path_eval in
  let interpreter =
    Interpreter.create_minimal ~self_component_name ~abi:target_abi
      ~staging_files_source ~prefix
  in
  {
    Context.eval = Interpreter.eval interpreter;
    path_eval = Interpreter.path_eval interpreter;
    target_abi_v2 = target_abi;
    log_config;
  }

let needs_install_admin ~reg ~selector ~log_config ~target_abi ~prefix
    ~staging_files_source =
  match
    Dkml_install_register.Component_registry.eval reg ~selector ~f:(fun cfg ->
        let module Cfg = (val cfg : Component_config) in
        let ctx =
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
        Result.ok ret)
  with
  | Ok bools -> List.exists Fun.id bools
  | Error msg -> raise (Installation_error msg)

let needs_uninstall_admin ~reg ~selector ~log_config ~target_abi ~prefix
    ~staging_files_source =
  match
    Dkml_install_register.Component_registry.eval reg ~selector ~f:(fun cfg ->
        let module Cfg = (val cfg : Component_config) in
        let ctx =
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
        Result.ok ret)
  with
  | Ok bools -> List.exists Fun.id bools
  | Error msg -> raise (Installation_error msg)

let spawn fatallog cmd =
  Logs.info (fun m -> m "Running: %a" Cmd.pp cmd);
  let handle_err msg =
    fatallog ~id:"5f927a8b" msg;
    Forward_progress.(Halted_progress Exit_transient_failure)
  in
  match OS.Cmd.(run_status cmd) with
  | Error e ->
      let msg =
        Fmt.str "@[Failed to run:@,@[%s@]@]@,@[%a@]" (Cmd.to_string cmd)
          Rresult.R.pp_msg e
      in
      handle_err msg
  | Ok (`Exited 0) -> Forward_progress.(return ((), fatallog))
  | Ok (`Exited v) ->
      handle_err @@ Fmt.str "Exited with exit code %d: %a" v Cmd.pp cmd
  | Ok (`Signaled v) ->
      handle_err @@ Fmt.str "Signaled with signal %d: %a" v Cmd.pp cmd

let console_component_name = "xx-console"

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
        Cmd.(
          v (Fpath.to_string gsudo) % "--wait" % "--direct" % "--debug" %% cmd)
    | Some _ | None ->
        Cmd.(v (Fpath.to_string gsudo) % "--wait" % "--direct" %% cmd)
  else
    match OS.Cmd.find_tool (Cmd.v "doas") with
    | Ok (Some fpath) -> Cmd.(v (Fpath.to_string fpath) %% cmd)
    | Ok None | Error _ -> (
        match OS.Cmd.find_tool (Cmd.v "sudo") with
        | Ok (Some fpath) -> Cmd.(v (Fpath.to_string fpath) %% cmd)
        | Ok None | Error _ ->
            let su =
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

let home_dir_fp () =
  let open Dkml_install_runner.Error_handling in
  let open Dkml_install_runner.Error_handling.Monad_syntax in
  let* home_str = map_rresult_error_to_string @@ OS.Env.req_var "HOME" in
  let* home_fp = map_rresult_error_to_string @@ Fpath.of_string home_str in
  (* ensure HOME is a pre-existing directory *)
  map_rresult_error_to_string @@ OS.Dir.must_exist home_fp

let get_default_user_installation_prefix_windows
    ~installation_prefix_camel_case_nospaces =
  let open Dkml_install_runner.Error_handling in
  let open Dkml_install_runner.Error_handling.Monad_syntax in
  let* local_app_data_str =
    map_rresult_error_to_string @@ OS.Env.req_var "LOCALAPPDATA"
  in
  let* local_app_data_fp =
    map_rresult_error_to_string @@ Fpath.of_string local_app_data_str
  in
  (* ensure LOCALAPPDATA is a pre-existing directory *)
  let* local_app_data_fp =
    map_rresult_error_to_string @@ OS.Dir.must_exist local_app_data_fp
  in
  Result.ok
    Fpath.(
      local_app_data_fp / "Programs" / installation_prefix_camel_case_nospaces)

let get_default_user_installation_prefix_darwin
    ~installation_prefix_camel_case_nospaces =
  let open Dkml_install_runner.Error_handling.Monad_syntax in
  let* home_dir_fp = home_dir_fp () in
  Result.ok
    Fpath.(
      home_dir_fp / "Applications" / installation_prefix_camel_case_nospaces)

let get_default_user_installation_prefix_linux
    ~installation_prefix_kebab_lower_case =
  let open Dkml_install_runner.Error_handling in
  let open Dkml_install_runner.Error_handling.Monad_syntax in
  match OS.Env.var "XDG_DATA_HOME" with
  | Some xdg_data_home ->
      let* fp = map_rresult_error_to_string @@ Fpath.of_string xdg_data_home in
      Result.ok Fpath.(fp / installation_prefix_kebab_lower_case)
  | None ->
      let* home_dir_fp = home_dir_fp () in
      Result.ok
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
  | Some prefix -> Fpath.v prefix
  | None ->
      let open Dkml_install_runner.Error_handling in
      (if Context.Abi_v2.is_windows target_abi then
       get_default_user_installation_prefix_windows
         ~installation_prefix_camel_case_nospaces
      else if Context.Abi_v2.is_darwin target_abi then
        get_default_user_installation_prefix_darwin
          ~installation_prefix_camel_case_nospaces
      else if Context.Abi_v2.is_linux target_abi then
        get_default_user_installation_prefix_linux
          ~installation_prefix_kebab_lower_case
      else
        Result.error
          (Fmt.str
             "[14420023] No rules defined for the default user installation \
              prefix of the ABI %a"
             Context.Abi_v2.pp target_abi))
      |> get_ok_or_raise_string

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
            (get_user_installation_prefix ~program_name ~target_abi
               ~prefix_opt:None)))
  in
  Cmdliner.Arg.(
    value
    & opt (some string) None
    & info
        [ Dkml_install_runner.Cmdliner_common.prefix_arg ]
        ~docv:"PREFIX" ~doc)

let package_args_t ~program_name ~target_abi =
  let package_args log_config prefix_opt component_selector static_files_source
      staging_files_source =
    {
      log_config;
      prefix_opt;
      component_selector;
      static_files_source;
      staging_files_source;
    }
  in
  Cmdliner.Term.(
    const package_args $ Dkml_install_runner.Cmdliner_runner.setup_log_t
    $ prefix_opt_t ~program_name ~target_abi
    $ Dkml_install_runner.Cmdliner_runner.component_selector_t ~install:true
    $ Dkml_install_runner.Cmdliner_runner.static_files_source_for_package_t
    $ Dkml_install_runner.Cmdliner_runner.staging_files_source_for_package_t)
