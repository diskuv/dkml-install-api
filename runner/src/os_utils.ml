(** [string_to_fpath str] converts [str] into a [Fpath.t]. On Windows the
    [str] is normalized to a regular Windows file path (ex. backslashes). *)
let string_to_norm_fpath str =
  match Fpath.of_string str with Ok p -> p | Error (`Msg e) -> failwith e

(** [normalize_path] normalizes a path so on Windows it is a regular
    Windows path with backslashes. *)
let normalize_path str = Fpath.(to_string (string_to_norm_fpath str))

type install_files_source =
  | Opam_switch_prefix of Fpath.t
  | Install_files_dir of Fpath.t

type install_files_type = Staging | Static
type package_selector = Package | Component

(** [absdir_install_files ~component_name install_files_type install_files_source] is
    the [component_name] component's static-files or staging-files directory
    for Staging or Static [install_files_type], respectively *)
let absdir_install_files ?(package_selector = Component) ~component_name
    install_files_type install_files_source =
  let do_opam_context opam_switch_prefix =
    let stem =
      match install_files_type with
      | Staging -> "staging-files"
      | Static -> "static-files"
    in
    Fpath.(
      opam_switch_prefix / "share"
      / (match package_selector with
        | Component -> "dkml-component-" ^ component_name
        | Package -> "dkml-package-" ^ component_name)
      / stem)
  in
  match install_files_source with
  | Opam_switch_prefix opam_switch_prefix -> do_opam_context opam_switch_prefix
  | Install_files_dir install_files -> Fpath.(install_files / component_name)
