type static_files_source = Opam_context_static | Static_files_dir of string

(* Check all components to see if _any_ needs admin *)

let staging_files_source ~opam_context ~staging_files_opt =
  match (opam_context, staging_files_opt) with
  | false, None ->
      raise
        (Dkml_install_api.Installation_error
           "Either `--opam-context` or `--staging-files DIR` must be specified")
  | true, _ -> Path_eval.Opam_context
  | false, Some staging_files -> Staging_files_dir staging_files

(** [absdir_static_files ~component_name static_files_source] is
        the [component_name] component's static-files directory *)
let absdir_static_files ~component_name = function
  | Opam_context_static ->
      Os_utils.absdir_install_files ~component_name Static Opam_context
  | Static_files_dir static_files ->
      Os_utils.absdir_install_files ~component_name Static
        (Install_files_dir static_files)
