val console_component_name : string
(** [console_component_name] is the name of the component that has executables
    that help run console installers (like gsudo.exe on Windows to elevate
    privileges). *)

val needs_install_admin :
  reg:Dkml_install_register.Component_registry.t ->
  selector:Dkml_install_register.Component_registry.component_selector ->
  log_config:Dkml_install_api.Log_config.t ->
  prefix:Fpath.t ->
  staging_files_source:Dkml_install_runner.Path_location.staging_files_source ->
  bool

val needs_uninstall_admin :
  reg:Dkml_install_register.Component_registry.t ->
  selector:Dkml_install_register.Component_registry.component_selector ->
  log_config:Dkml_install_api.Log_config.t ->
  prefix:Fpath.t ->
  staging_files_source:Dkml_install_runner.Path_location.staging_files_source ->
  bool

(** {1 Running Programs} *)

val spawn : Bos.Cmd.t -> (unit, string) result
(** [spawn cmd] launches the command [cmd] and waits for its response. *)

val elevated_cmd :
  staging_files_source:Dkml_install_runner.Path_location.staging_files_source ->
  Bos.Cmd.t ->
  Bos.Cmd.t
(** [elevated_cmd ~staging_files_source cmd] translates the command [cmd]
    into a command that elevates privileges using ["gsudo.exe"] from the staging
    files [staging_files_source] on Windows machines, or ["doas"], ["sudo"] or
    ["su"] on the PATH on Unix machines. *)

(** {1 Installation Paths} *)

type program_name = {
  name_full : string;
  name_camel_case_nospaces : string;
  name_kebab_lower_case : string;
}
(** The type of program names.

    [name_full] - Examples include "Diskuv OCaml"

    [name_camel_case_nospaces] - If the program name was "Diskuv OCaml" then
      the [name_camel_case_nospaces] could be either "DiskuvOCaml" or
      "DiskuvOcaml".

    [name_kebab_lower_case] - If the program name was "Diskuv OCaml" then
      the [name_kebab_lower_case] would be "diskuv-ocaml".
*)

val get_user_installation_prefix :
  program_name:program_name -> prefix_opt:string option -> Fpath.t
(** [get_user_installation_prefix ~program_name ~prefix_opt ~prefer_spaces]
    returns where user programs should be installed; either the prefix
    [prefix_opt = Some prefix] or uses the platform convention
    when [prefix_opt = None].

    {1 Platform Conventions}

    The user programs would be installed to these locations by default:

    Windows: ["$env:LOCALAPPDATA\\Programs\\<name_full>"] when
      [prefer_spaces = False] or
      ["$env:LOCALAPPDATA\\Programs\\<name_camel_case_nospaces>"] otherwise.
      This pattern closely conforms to the standard established by
      ["$env:LOCALAPPDATA\\Programs\\Microsoft VS Code"]

    macOS: ["~/Applications/<name_full>.app"] when
      [prefer_spaces = False] or
      ["~/Applications/<name_camel_case_nospaces>.app"] otherwise.

    Linux: If ["$XDG_DATA_HOME"] is defined then
      ["$XDG_DATA_HOME/<name_kebab_lower_case>"]
      otherwise ["$HOME/.local/share/<name_kebab_lower_case>"]
    *)

(** {1 Command Line Processing} *)

type package_args = {
  log_config : Dkml_install_api.Log_config.t;
  prefix_opt : string option;
  component_selector : string list;
  static_files_source : Dkml_install_runner.Path_location.static_files_source;
  staging_files_source : Dkml_install_runner.Path_location.staging_files_source;
}
(** Common options between setup.exe and uninstaller.exe *)

val package_args_t : program_name:program_name -> package_args Cmdliner.Term.t
(** {!Cmdliner.Term.t} for the common options between setup.exe and
    uninstaller.exe *)
