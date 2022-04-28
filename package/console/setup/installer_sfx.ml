(* Documentation: https://info.nrao.edu/computing/guide/file-access-and-archiving/7zip/7z-7za-command-line-guide

   Beware that the 7zip configuration file is usually CRLF, and must always be
   UTF-8. *)

open Bos

(** Highest compression. *)
let sevenz_compression_level_opts = Cmd.v "-mx9"

let sevenz_log_level_opts =
  (* 7z is super chatty! *)
  let output_log_level_min = Cmd.v "-bb0" in
  let output_log_level_max = Cmd.v "-bb3" in
  let disable_stdout_stream = Cmd.v "-bso0" in
  match Logs.level () with
  | Some Debug -> output_log_level_max
  | Some Info -> Cmd.(output_log_level_min %% disable_stdout_stream)
  | _ -> disable_stdout_stream

let create_7z_archive ~sevenz_exe ~archive_path ~archive_dir =
  let ( let* ) = Rresult.R.bind in
  let pwd = Error_utils.get_ok_or_failwith_rresult (OS.Dir.current ()) in
  let archive_rel_dir =
    if Fpath.is_rel archive_dir then Fpath.(v "." // archive_dir)
    else
      match Fpath.relativize ~root:pwd archive_dir with
      | Some v -> v
      | None ->
          let msg =
            Fmt.str "The archive directory %a cannot be made relative to %a"
              Fpath.pp archive_dir Fpath.pp pwd
          in
          Logs.info (fun l -> l "FATAL: %s" msg);
          failwith msg
  in
  let run_7z cmd action =
    let* status = OS.Cmd.run_status cmd in
    match status with
    | `Exited 0 -> Ok ()
    | `Exited status ->
        let msg =
          Fmt.str "%a could not %s. Exited with error code %d" Fpath.pp
            sevenz_exe action status
        in
        Logs.err (fun l -> l "FATAL: %s" msg);
        failwith msg
    | `Signaled signal ->
        (* https://stackoverflow.com/questions/1101957/are-there-any-standard-exit-status-codes-in-linux/1535733#1535733 *)
        let msg =
          Fmt.str "%a could not %s. Exited with signal %d" Fpath.pp sevenz_exe
            action signal
        in
        Logs.err (fun l -> l "FATAL: %s" msg);
        failwith msg
  in

  let cmd_create =
    Cmd.(
      v (Fpath.to_string sevenz_exe)
      % "a" %% sevenz_log_level_opts %% sevenz_compression_level_opts % "-y"
      % Fpath.to_string archive_path
      (* DIR/* is 7z's syntax for the contents of DIR *)
      % Fpath.(to_string (archive_rel_dir / "*")))
  in
  Logs.info (fun l -> l "Creating 7z archive with: %a" Cmd.pp cmd_create);
  let* () = run_7z cmd_create "create a self-extracting archive" in

  (* 7xS2con.sfx and 7xS2.sfx will autolaunch "setup.exe" (or the first .exe,
     which is ambiguous). We'll rename bin/dkml-console-setup-proxy.exe so that
     it is setup.exe.

     Syntax:
      rn <archive_name> <src_file_1> <dest_file_1> [ <src_file_2> <dest_file_2> ... ]

     Confer: https://documentation.help/7-Zip-18.0/rename.htm
  *)
  let cmd_rename =
    Cmd.(
      v (Fpath.to_string sevenz_exe)
      % "rn" %% sevenz_log_level_opts %% sevenz_compression_level_opts % "-y"
      % Fpath.to_string archive_path
      % "bin/dkml-console-setup-proxy.exe" % "setup.exe")
  in
  Logs.info (fun l ->
      l "Renaming within a 7z archive with: %a" Cmd.pp cmd_rename);
  run_7z cmd_rename "rename within a self-extracting archive"

let create_7z_sfx ~sfx ~archive_path ~installer_path =
  Error_utils.get_ok_or_failwith_rresult
  @@ OS.File.with_output installer_path
       (fun output () ->
         (* Mimic DOS command given in 7z documentation:
             copy /b 7zS.sfx + config.txt + archive.7z archive.exe *)

         (* 7zS.sfx or something similar *)
         output (Some (sfx, 0, Bytes.length sfx));

         (* archive.7z. just copy it block by block *)
         let rec helper input =
           match input () with
           | Some (b, pos, len) ->
               output (Some (b, pos, len));
               helper input
           | None -> ()
         in
         Error_utils.get_ok_or_failwith_rresult
         @@ OS.File.with_input archive_path (fun input () -> helper input) ();

         (* EOF *)
         output None;
         Ok ())
       ()

let modify_manifest ~work_dir ~installer_path ~organization ~program_name
    ~program_version =
  let ( let* ) = Rresult.R.bind in
  let translate s =
    Str.(
      s
      |> global_replace
           (regexp_string "__PLACEHOLDER_ORG_NOSPACE__")
           organization
             .Dkml_package_console_common.common_name_camel_case_nospaces
      |> global_replace
           (regexp_string "__PLACEHOLDER_PROGRAM_NOSPACE__")
           program_name.Dkml_package_console_common.name_camel_case_nospaces
      |> global_replace
           (regexp_string "__PLACEHOLDER_VERSION_MNOP__")
           (Dkml_package_console_common.version_m_n_o_p program_version))
  in
  let* manifest =
    let path = Fpath.(work_dir / "setup.exe.manifest") in
    let content = Option.get (Manifests.read "setup.exe.manifest") in
    let* () = OS.File.write path (translate content) in
    Ok path
  in
  let* mt_exe = OS.Cmd.get_tool (Cmd.v "mt") in
  let cmd =
    Cmd.(
      v (Fpath.to_string mt_exe)
      % "-manifest" % Fpath.to_string manifest % "-verbose"
      % "-validate_manifest"
      % Fmt.str "-outputresource:%a;1" Fpath.pp installer_path)
  in
  let* status = OS.Cmd.run_status cmd in
  match status with
  | `Exited 0 -> Ok ()
  | `Exited status ->
      let msg =
        Fmt.str "%a could not modify the manifest. Exited with error code %d"
          Fpath.pp mt_exe status
      in
      Logs.err (fun l -> l "FATAL: %s" msg);
      failwith msg
  | `Signaled signal ->
      (* https://stackoverflow.com/questions/1101957/are-there-any-standard-exit-status-codes-in-linux/1535733#1535733 *)
      let msg =
        Fmt.str "%a could not modify the manifest. Exited with signal %d"
          Fpath.pp mt_exe signal
      in
      Logs.err (fun l -> l "FATAL: %s" msg);
      failwith msg

let generate ~archive_dir ~target_dir ~abi_selector ~organization ~program_name
    ~program_version ~work_dir =
  let abi_name =
    Dkml_install_runner.Path_location.show_abi_selector abi_selector
  in
  let program_name_kebab_lower_case =
    program_name.Dkml_package_console_common.name_kebab_lower_case
  in
  let installer_basename =
    Fmt.str "setup-%s-%s-%s.exe" program_name_kebab_lower_case abi_name
      program_version
  in
  Logs.info (fun l -> l "Generating %s" installer_basename);
  Error_utils.get_ok_or_failwith_rresult
    (let ( let* ) = Rresult.R.bind in
     let sfx_dir = Fpath.(work_dir / "sfx") in
     let archive_path =
       Fpath.(
         target_dir
         / Fmt.str "%s-%s-%s.7z" program_name_kebab_lower_case abi_name
             program_version)
     in
     let installer_path = Fpath.(target_dir / installer_basename) in
     let sevenz_exe = Fpath.(sfx_dir / "7zr.exe") in
     let* (_was_created : bool) = OS.Dir.create sfx_dir in
     let* () =
       OS.File.write ~mode:0o750 sevenz_exe
         (Option.get (Seven_z.read "7zr.exe"))
     in
     let sfx = Bytes.of_string (Option.get (Seven_z.read "7zS2con.sfx")) in
     let* () = create_7z_archive ~sevenz_exe ~archive_path ~archive_dir in
     let* () = create_7z_sfx ~sfx ~archive_path ~installer_path in
     let* () =
       modify_manifest ~work_dir ~installer_path ~organization ~program_name
         ~program_version
     in
     Ok ())
