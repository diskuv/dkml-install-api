type static_files_source =
  | Opam_static_switch_prefix of string
  | Static_files_dir of string

type staging_files_source =
  | Opam_staging_switch_prefix of string
  | Staging_files_dir of string

type abi_selector = Generic | Abi of Dkml_install_api.Context.Abi_v2.t

let staging_files_source ~opam_context_opt ~staging_files_opt =
  match (opam_context_opt, staging_files_opt) with
  | None, None ->
      raise
        (Dkml_install_api.Installation_error
           "Either `--opam-context [SWITCH_PREFIX]` or `--staging-files DIR` \
            must be specified")
  | Some switch_prefix, None -> Opam_staging_switch_prefix switch_prefix
  | None, Some staging_files -> Staging_files_dir staging_files
  | Some _, Some _ ->
      raise
        (Dkml_install_api.Installation_error
           "Only one, not both, of `--opam-context [SWITCH_PREFIX]` and \
            `--staging-files DIR` should be specified.")

(** [absdir_static_files ~component_name static_files_source] is
        the [component_name] component's static-files directory *)
let absdir_static_files ~component_name = function
  | Opam_static_switch_prefix switch_prefix ->
      Os_utils.absdir_install_files ~component_name Static
        (Opam_switch_prefix switch_prefix)
  | Static_files_dir static_files ->
      Os_utils.absdir_install_files ~component_name Static
        (Install_files_dir static_files)

(** [absdir_staging_files ~component_name ~abi_selector staging_files_source] is
    the [component_name] component's staging-files/(generic|<arch>) directory *)
let absdir_staging_files ?(package_selector = Os_utils.Component)
    ~component_name ~abi_selector staging_files_source =
  let append_with_abi s =
    match abi_selector with
    | Generic -> Fpath.(v s / "generic" |> to_string)
    | Abi abi ->
        Fpath.(
          v s / Dkml_install_api.Context.Abi_v2.to_canonical_string abi
          |> to_string)
  in
  match staging_files_source with
  | Opam_staging_switch_prefix switch_prefix ->
      append_with_abi
        (Os_utils.absdir_install_files ~package_selector ~component_name Staging
           (Opam_switch_prefix switch_prefix))
  | Staging_files_dir staging_files ->
      append_with_abi
        (Os_utils.absdir_install_files ~package_selector ~component_name Staging
           (Install_files_dir staging_files))
