(** Creates archives meant to be unpacked by an end-user, with a setup
    executable inside.
    
    This module creates a shell script that you need to run to produce
    a final archive.tar.gz, archive.tar.bz2, etc. *)

open Bos

let generate ~archive_dir ~target_dir ~abi_selector ~program_name
    ~program_version =
  let abi_name =
    Dkml_install_runner.Path_location.show_abi_selector abi_selector
  in
  let program_name_kebab_lower_case =
    program_name.Dkml_package_console_common.name_kebab_lower_case
  in
  let installer_basename_without_ver =
    Fmt.str "%s-%s" program_name_kebab_lower_case abi_name
  in
  let installer_basename_with_ver =
    Fmt.str "%s-%s-%s" program_name_kebab_lower_case abi_name program_version
  in
  let installer_create_sh =
    Fpath.(target_dir / ("bundle-" ^ installer_basename_without_ver ^ ".sh"))
  in
  let buildhost_abi =
    match Dkml_install_runner.Host_abi.create_v2 () with
    | Ok v -> Dkml_install_api.Context.Abi_v2.to_canonical_string v
    | _ -> "unknown_abi"
  in
  let translate s =
    Str.(
      s
      |> global_replace
           (regexp_string "__PLACEHOLDER_BASENAME__")
           installer_basename_with_ver
      |> global_replace
           (regexp_string "__PLACEHOLDER_BUILDHOST_ABI__")
           buildhost_abi
      |> global_replace
           (regexp_string "__PLACEHOLDER_ARCHIVE_DIR__")
           (Fpath.to_string archive_dir))
  in
  Logs.info (fun l ->
      l "Generating script %a that can produce %s.tar.gz (etc.) archives"
        Fpath.pp installer_create_sh installer_basename_with_ver);
  Dkml_package_console_common.get_ok_or_failwith_rresult
    (OS.File.write ~mode:0o750 installer_create_sh
       (translate (Option.get (Shell_scripts.read "bundle.sh"))))
