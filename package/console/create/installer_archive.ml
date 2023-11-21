(** Creates archives meant to be unpacked by an end-user, with a setup
    executable inside.
    
    This module creates a shell script that you need to run to produce
    a final archive.tar.gz, archive.tar.bz2, etc. *)

open Bos
open Dkml_install_runner.Error_handling.Monad_syntax

let build_bundle_sh ~installer_basename_with_direction_and_ver ~buildhost_abi
    ~archive_dir =
  let template = Option.get (Shell_scripts.read "bundle.sh") in
  let archive_dir = Fpath.to_string archive_dir in
  let replace_placeholder exact_match repl s =
    let open Astring.String in
    concat ~sep:repl (cuts ~empty:true ~sep:exact_match s)
  in
  let translate s =
    s
    |> replace_placeholder "__PLACEHOLDER_BASENAME__"
         installer_basename_with_direction_and_ver
    |> replace_placeholder "__PLACEHOLDER_BUILDHOST_ABI__" buildhost_abi
    |> replace_placeholder "__PLACEHOLDER_ARCHIVE_DIR__" archive_dir
  in
  translate template

let generate ~(install_direction : Dkml_install_register.install_direction)
    ~archive_dir ~target_dir ~abi_selector ~program_name ~program_version =
  let abi_name =
    Dkml_install_runner.Path_location.show_abi_selector abi_selector
  in
  let program_name_kebab_lower_case =
    program_name.Dkml_package_console_common.Author_types.name_kebab_lower_case
  in
  let direction =
    match install_direction with Install -> "i" | Uninstall -> "u"
  in
  let installer_basename_with_direction_and_ver =
    Fmt.str "%s-%s-%s-%s" program_name_kebab_lower_case abi_name direction
      program_version
  in
  let installer_create_sh =
    Fpath.(
      target_dir
      / Printf.sprintf "bundle-%s-%s-%s.sh" program_name_kebab_lower_case
          abi_name direction)
  in
  let* buildhost_abi', _fl = Dkml_install_runner.Host_abi.create_v2 () in
  let buildhost_abi =
    Dkml_install_api.Context.Abi_v2.to_canonical_string buildhost_abi'
  in
  let bundle_sh =
    build_bundle_sh ~installer_basename_with_direction_and_ver ~buildhost_abi
      ~archive_dir
  in
  Logs.info (fun l ->
      l "Generating script %a that can produce %s.tar.gz (etc.) archives"
        Fpath.pp installer_create_sh installer_basename_with_direction_and_ver);
  Dkml_install_runner.Error_handling.map_rresult_error_to_progress
    (OS.File.write ~mode:0o750 installer_create_sh bundle_sh)
