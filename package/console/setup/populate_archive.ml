open Bos
open Error_utils

let copy_dir_if_exists ~src ~dst =
  match OS.Dir.exists src with
  | Ok true ->
      get_ok_or_failwith_string (Diskuvbox.copy_dir ~err:box_err ~src ~dst ())
  | Ok false -> ()
  | Error msg ->
      Logs.err (fun l -> l "FATAL: %a" Rresult.R.pp_msg msg);
      failwith (Fmt.str "%a" Rresult.R.pp_msg msg)

let populate_archive ~archive_dir ~packager_setup_bytecode ~packager_uninstaller_bytecode ~opam_context
    ~all_component_names =
  (* Make a `.archivetree` empty file so executables like
     bin/dkml-package-setup.bc can be renamed setup.exe, but still
     setup.exe will be able to locate all the other archive files. *)
  get_ok_or_failwith_string
    (Diskuvbox.touch_file ~err:box_err
       ~file:Fpath.(archive_dir / ".archivetree")
       ());
  (* Copy runner binaries. TODO: Should these be bytecode, not .exe? *)
  get_ok_or_failwith_string
    (Diskuvbox.copy_file ~err:box_err
       ~src:Fpath.(opam_context / "bin" / "dkml-install-admin-runner.exe")
       ~dst:Fpath.(archive_dir / "bin" / "dkml-install-admin-runner.exe")
       ());
  get_ok_or_failwith_string
    (Diskuvbox.copy_file ~err:box_err
       ~src:Fpath.(opam_context / "bin" / "dkml-install-user-runner.exe")
       ~dst:Fpath.(archive_dir / "bin" / "dkml-install-user-runner.exe")
       ());
  (* Copy dkml-package-setup/uninstaller binaries. *)
  get_ok_or_failwith_string
    (Diskuvbox.copy_file ~err:box_err
       ~src:Fpath.(opam_context / "bin" / "dkml-console-setup-proxy.exe")
       ~dst:Fpath.(archive_dir / "bin" / "dkml-console-setup-proxy.exe")
       ());
  get_ok_or_failwith_string
    (Diskuvbox.copy_file ~err:box_err ~src:packager_setup_bytecode
       ~dst:Fpath.(archive_dir / "bin" / "dkml-package-setup.bc")
       ());
  get_ok_or_failwith_string
    (Diskuvbox.copy_file ~err:box_err ~src:packager_uninstaller_bytecode
       ~dst:Fpath.(archive_dir / "bin" / "dkml-package-uninstaller.bc")
       ());
  (* Copy lib/dkml-install-runner/plugins *)
  get_ok_or_failwith_string
    (Diskuvbox.copy_dir ~err:box_err
       ~src:Fpath.(opam_context / "lib" / "dkml-install-runner" / "plugins")
       ~dst:Fpath.(archive_dir / "lib" / "dkml-install-runner" / "plugins")
       ());
  (* Copy lib/dkml-component-<component>/ *)
  List.iter
    (fun component_name ->
      let pkg = "dkml-component-" ^ component_name in
      get_ok_or_failwith_string
        (Diskuvbox.copy_dir ~err:box_err
           ~src:Fpath.(opam_context / "lib" / pkg)
           ~dst:Fpath.(archive_dir / "lib" / pkg)
           ()))
    all_component_names

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
