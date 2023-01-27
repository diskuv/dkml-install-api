val console_component_name : string
(** [console_component_name] is the name of the component that has executables
    that help run console installers (like gsudo.exe on Windows to elevate
    privileges). *)

val console_required_components : string list
(** [console_required_components] are the names of components that console
    installers require to be present. It always includes
    {!console_component_name} but may include other components.

    At minimum, these other required components include:

    - ["staging-ocamlrun"] because {!Dkml_package_console_entry.entry} uses
      ocamlrun to run the dkml-package.bc bytecode. *)

val needs_install_admin :
  reg:Dkml_install_register.Component_registry.t ->
  selector:Dkml_install_register.Component_registry.component_selector ->
  log_config:Dkml_install_api.Log_config.t ->
  target_abi:Dkml_install_api.Context.Abi_v2.t ->
  prefix:Fpath.t ->
  staging_files_source:Dkml_install_runner.Path_location.staging_files_source ->
  bool Dkml_install_api.Forward_progress.t

val needs_uninstall_admin :
  reg:Dkml_install_register.Component_registry.t ->
  selector:Dkml_install_register.Component_registry.component_selector ->
  log_config:Dkml_install_api.Log_config.t ->
  target_abi:Dkml_install_api.Context.Abi_v2.t ->
  prefix:Fpath.t ->
  staging_files_source:Dkml_install_runner.Path_location.staging_files_source ->
  bool Dkml_install_api.Forward_progress.t

(** {1 Error Handling} *)

val get_ok_or_failwith_string : ('a, string) result -> 'a
val get_ok_or_failwith_rresult : ('a, Rresult.R.msg) result -> 'a
val box_err : string -> 'a

(** {1 Author Supplied Types} *)

module Author_types : sig
  type program_name = {
    name_full : string;
    name_camel_case_nospaces : string;
    name_kebab_lower_case : string;
    installation_prefix_camel_case_nospaces_opt : string option;
    installation_prefix_kebab_lower_case_opt : string option;
  }
  (** The type of program names.

    [name_full] - Examples include "Diskuv OCaml"

    [name_camel_case_nospaces] - If the program name was "Diskuv OCaml" then
      the [name_camel_case_nospaces] could be either "DiskuvOCaml" or
      "DiskuvOcaml".

    [name_kebab_lower_case] - If the program name was "Diskuv OCaml" then
      the [name_kebab_lower_case] would be "diskuv-ocaml".

    [installation_prefix_camel_case_nospaces_opt] - The name used when
      constructing an installation prefix that takes a CamelCase with no spaces.
      If not specified, then [name_camel_case_nospaces] is used.

    [installation_prefix_kebab_lower_case_opt] - The name used when
      constructing an installation prefix that takes a kebab-lower-case.
      If not specified, then [name_kebab_lower_case] is used.
  *)

  type organization = {
    legal_name : string;
    common_name_full : string;
    common_name_camel_case_nospaces : string;
    common_name_kebab_lower_case : string;
  }
  (** Details about the organization for signing binaries.

    [legal_name] - Examples include "Diskuv, Inc."

    [common_name_full] - Examples include "Dow Jones"

    [common_name_camel_case_nospaces] - If the common name was "Dow Jones" then
      the [common_name_camel_case_nospaces] would be "DowJones".

    [common_name_kebab_lower_case] - If the program name was "Dow Jones" then
      the [common_name_kebab_lower_case] would be "dow-jones".

  *)

  type program_assets = { logo_icon_32x32_opt : string option }
  (** Logos and other assets used during installation.

    [logo_icon_32x32_opt] - [None] or the [Some icon_data] where [icon_data] is
      the contents of the 32x32 icon file. Do not use a filename or a URL;
      instead read the file into a string. Using the
      {{:https://github.com/mirage/ocaml-crunch#readme} ocaml-crunch} package
      will automate this for you.
  *)

  type program_info = {
    url_info_about_opt : string option;
    url_update_info_opt : string option;
    help_link_opt : string option;
    estimated_byte_size_opt : int64 option;
    windows_language_code_id_opt : int option;
    embeds_32bit_uninstaller : bool;
    embeds_64bit_uninstaller : bool;
  }
  (** Information about the program.

    [url_info_about_opt] - A URL to a webpage describing the program.

    [url_update_info_opt] - A URL to a webpage describing updates to the
      program.

    [help_link_opt] - A URL to a help webpage.

    [estimated_byte_size_opt] - How much disk space, in bytes, is estimated to
      be taken away after the installation is complete.

    [windows_language_code_id_opt] - The Language ID for a Windows installation from
      https://docs.microsoft.com/en-us/openspecs/windows_protocols/ms-lcid/70feba9f-294e-491e-b6eb-56532684c37f.
      Defaults to 0x0409 (en-US).

      A simpler non-exhaustive list is at
      https://docs.microsoft.com/en-us/openspecs/office_standards/ms-oe376/6c085406-a698-4e12-9d4d-c3b0ee3dbc4a
  *)
end

val version_m_n_o_p : string -> string
(** [ver_m_n_o_p ver] converts the version [ver] into the
["mmmmm.nnnnn.ooooo.ppppp"] format required by an Application Manifest.

Confer https://docs.microsoft.com/en-us/windows/win32/sbscs/application-manifests#assemblyidentity *)

(** {1 Running Programs} *)

val spawn :
  ?err_ok:bool -> Bos.Cmd.t -> unit Dkml_install_api.Forward_progress.t
(** [spawn ?err_ok cmd] launches the command [cmd] and waits for its response.

    Use [err_ok = true] if you want to log errors but continue. *)

val elevated_cmd :
  target_abi:Dkml_install_api.Context.Abi_v2.t ->
  staging_files_source:Dkml_install_runner.Path_location.staging_files_source ->
  Bos.Cmd.t ->
  Bos.Cmd.t Dkml_install_api.Forward_progress.t
(** [elevated_cmd ~target_abi ~staging_files_source cmd] translates the command [cmd]
    into a command that elevates privileges using ["gsudo.exe"] from the staging
    files [staging_files_source] on Windows machines, or ["doas"], ["sudo"] or
    ["su"] on the PATH on Unix machines. *)

(** {1 Installation Paths} *)

val get_user_installation_prefix :
  program_name:Author_types.program_name ->
  target_abi:Dkml_install_api__Types.Context.Abi_v2.t ->
  prefix_opt:string option ->
  Fpath.t Dkml_install_api.Forward_progress.t
(** [get_user_installation_prefix ~program_name ~target_abi ~prefix_opt]
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

val package_args_t :
  program_name:Author_types.program_name ->
  target_abi:Dkml_install_api__Types.Context.Abi_v2.t ->
  install_direction:
    Dkml_install_runner.Path_eval.Global_context.install_direction ->
  package_args Cmdliner.Term.t
(** {!Cmdliner.Term.t} for the common options between setup.exe and
    uninstaller.exe *)

module Windows_registry : sig
  val delete_program_entry :
    program_name:Author_types.program_name ->
    unit Dkml_install_api.Forward_progress.t
  (** Delete from the Windows registry so that the program will not appear in
      Add/Remove Programs *)

  val write_program_entry :
    installation_prefix:Fpath.t ->
    organization:Author_types.organization ->
    program_name:Author_types.program_name ->
    program_assets:Author_types.program_assets ->
    program_version:string ->
    program_info:Author_types.program_info ->
    unit Dkml_install_api.Forward_progress.t
  (** Write into the Windows registry so that the program will appear Add/Remove
      Programs *)
end
