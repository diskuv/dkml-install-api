open Bos
open Dkml_package_console_common

let copy_dir_if_exists ~src ~dst =
  match OS.Dir.exists src with
  | Ok true ->
      get_ok_or_failwith_string (Diskuvbox.copy_dir ~err:box_err ~src ~dst ())
  | Ok false -> ()
  | Error msg ->
      Logs.err (fun l -> l "FATAL: %a" Rresult.R.pp_msg msg);
      failwith (Fmt.str "%a" Rresult.R.pp_msg msg)

let copy_file ~src ~dst =
  get_ok_or_failwith_string (Diskuvbox.copy_file ~err:box_err ~src ~dst ())

let populate_archive ~archive_dir ~abi_selector ~runner_admin_exe
    ~runner_user_exe ~packager_entry_exe ~packager_bytecode =
  (* Make a `.archivetree` empty file so executables like
     bin/dkml-package-setup.bc can be renamed setup.exe, but still
     setup.exe will be able to locate all the other archive files. *)
  get_ok_or_failwith_string
    (Diskuvbox.touch_file ~err:box_err
       ~file:Fpath.(archive_dir / ".archivetree")
       ());
  match abi_selector with
  | Dkml_install_runner.Path_location.Generic -> ()
  | Abi abi ->
      (* Define [resolve p] which will get the cross-compiled path if present; otherwise
         the default (native) path. Paths with $(dune-context) are necessary
         to get cross-compiled paths. *)
      let dune_abi_context =
        "default." ^ Dkml_install_api.Context.Abi_v2.to_canonical_string abi
      in
      let dune_abi_defs =
        Astring.String.Map.singleton "dune-context" dune_abi_context
      in
      let dune_default_defs =
        Astring.String.Map.singleton "dune-context" "default"
      in
      let resolve p =
        let pat = Pat.v (Fpath.to_string p) in
        let abi_resolution = Fpath.v (Pat.format dune_abi_defs pat) in
        if get_ok_or_failwith_rresult (OS.File.exists abi_resolution) then
          abi_resolution
        else Fpath.v (Pat.format dune_default_defs pat)
      in
      (* Copy runner binaries. TODO: Should these be bytecode, not .exe? *)
      get_ok_or_failwith_string
        (Diskuvbox.copy_file ~err:box_err ~src:(resolve runner_admin_exe)
           ~dst:Fpath.(archive_dir / "bin" / "dkml-install-admin-runner.exe")
           ());
      get_ok_or_failwith_string
        (Diskuvbox.copy_file ~err:box_err ~src:(resolve runner_user_exe)
           ~dst:Fpath.(archive_dir / "bin" / "dkml-install-user-runner.exe")
           ());
      (* Copy dkml-package-setup/uninstaller binaries. *)
      get_ok_or_failwith_string
        (Diskuvbox.copy_file ~err:box_err
           ~src:(resolve packager_entry_exe)
           ~dst:Fpath.(archive_dir / "bin" / "dkml-package-entry.exe")
           ());
      get_ok_or_failwith_string
        (Diskuvbox.copy_file ~err:box_err
           ~src:(resolve packager_bytecode)
           ~dst:Fpath.(archive_dir / "bin" / "dkml-package.bc")
           ())

let populate_archive_component ~component_name ~abi_selector
    ~opam_staging_files_source ~opam_static_files_source
    ~archive_staging_files_dest ~archive_static_files_dest =
  (* Copy staging for Generic *)
  let src_dir =
    Dkml_install_runner.Path_location.absdir_staging_files ~component_name
      ~abi_selector:Generic opam_staging_files_source
  in
  let dst_dir =
    Dkml_install_runner.Path_location.absdir_staging_files ~component_name
      ~abi_selector:Generic archive_staging_files_dest
  in
  copy_dir_if_exists ~src:src_dir ~dst:dst_dir;
  (* Copy staging for the ABI *)
  let src_dir =
    Dkml_install_runner.Path_location.absdir_staging_files ~component_name
      ~abi_selector opam_staging_files_source
  in
  let dst_dir =
    Dkml_install_runner.Path_location.absdir_staging_files ~component_name
      ~abi_selector archive_staging_files_dest
  in
  copy_dir_if_exists ~src:src_dir ~dst:dst_dir;
  (* Copy static *)
  let src_dir =
    Dkml_install_runner.Path_location.absdir_static_files ~component_name
      opam_static_files_source
  in
  let dst_dir =
    Dkml_install_runner.Path_location.absdir_static_files ~component_name
      archive_static_files_dest
  in
  copy_dir_if_exists ~src:src_dir ~dst:dst_dir
