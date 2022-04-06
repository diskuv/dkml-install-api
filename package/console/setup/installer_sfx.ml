(* Documentation: https://info.nrao.edu/computing/guide/file-access-and-archiving/7zip/7z-7za-command-line-guide

   Beware that the 7zip configuration file is usually CRLF, and must always be
   UTF-8. *)

open Bos
open Astring

let create_7z_archive ~sevenz_exe ~archive_path ~archive_dir =
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
  let log_level =
    match Logs.level () with
    | Some Debug -> Cmd.v "-bb3"
    | Some Info -> Cmd.v "-bb0"
    | _ -> Cmd.empty
  in
  let cmd =
    Cmd.(
      v (Fpath.to_string sevenz_exe)
      % "a" %% log_level % "-mx9" % "-y"
      % Fpath.to_string archive_path
      (* DIR/* is 7z's syntax for the contents of DIR *)
      % Fpath.(to_string (archive_rel_dir / "*")))
  in
  Logs.info (fun l -> l "Creating 7z archive with: %a" Cmd.pp cmd);
  let status = Error_utils.get_ok_or_failwith_rresult (OS.Cmd.run_status cmd) in
  match status with
  | `Exited 0 -> ()
  | `Exited status ->
      let msg =
        Fmt.str
          "7z.exe could not create a self-extracting archive. Exited with \
           error code %d"
          status
      in
      Logs.err (fun l -> l "FATAL: %s" msg);
      failwith msg
  | `Signaled signal ->
      (* https://stackoverflow.com/questions/1101957/are-there-any-standard-exit-status-codes-in-linux/1535733#1535733 *)
      let msg =
        Fmt.str
          "7z.exe could not create a self-extracting archive. Exited with \
           signal %d"
          signal
      in
      Logs.err (fun l -> l "FATAL: %s" msg);
      failwith msg

let get_config_text ~program_title ~program_version =
  let text =
    {|;!@Install@!UTF-8!
Title="__TITLE__"
BeginPrompt="Do you want to install __TITLE__?"
ExecuteFile="msiexec.exe"
ExecuteParameters="/i blahblah.msi REINSTALL=ALL REINSTALLMODE=vomus"
;!@InstallEnd@!|}
  in
  let text' =
    Str.global_replace
      (Str.regexp_string "__TITLE__")
      (program_title ^ " " ^ program_version)
      text
  in
  let lines = String.cuts ~sep:"\n" text' in
  (* Remove trailing carriage returns, if any, and then add in CRLF *)
  let trimmed_lines = List.map (fun s -> String.trim s ^ "\r\n") lines in
  (* Reconstitute as one string *)
  String.concat trimmed_lines

let create_7z_sfx ~sfx ~archive_path ~installer_path ~program_title
    ~program_version =
  Error_utils.get_ok_or_failwith_rresult
  @@ Error_utils.get_ok_or_failwith_rresult
  @@ OS.File.with_output installer_path
       (fun output () ->
         (* Mimic DOS command given in 7z documentation:
             copy /b 7zS.sfx + config.txt + archive.7z archive.exe *)

         (* 7zCon.sfx *)
         output (Some (sfx, 0, Bytes.length sfx));

         (* config.txt. none currently. *)
         let config_txt =
           Bytes.of_string (get_config_text ~program_title ~program_version)
         in
         output (Some (config_txt, 0, Bytes.length config_txt));

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

let generate ~archive_dir ~target_dir ~abi_selector ~program_title ~program_name
    ~program_version ~work_dir =
  let abi_name =
    Dkml_install_runner.Path_location.show_abi_selector abi_selector
  in
  let installer_basename =
    Fmt.str "setup-%s-%s-%s.exe" program_name abi_name program_version
  in
  Logs.info (fun l -> l "Generating %s" installer_basename);
  Error_utils.get_ok_or_failwith_rresult
    (let ( let* ) = Rresult.R.bind in
     let sfx_dir = Fpath.(work_dir / "sfx") in
     let archive_path =
       Fpath.(
         target_dir
         / Fmt.str "%s-%s-%s.7z" program_name abi_name program_version)
     in
     let installer_path = Fpath.(target_dir / installer_basename) in
     let sevenz_exe = Fpath.(sfx_dir / "7z.exe") in
     let sevenz_dll = Fpath.(sfx_dir / "7z.dll") in
     let* (_was_created : bool) = OS.Dir.create sfx_dir in
     let* () =
       OS.File.write ~mode:0o750 sevenz_exe (Option.get (Seven_z.read "7z.exe"))
     in
     let* () =
       OS.File.write ~mode:0o750 sevenz_dll (Option.get (Seven_z.read "7z.dll"))
     in
     let sfx = Bytes.of_string (Option.get (Seven_z.read "7zSD.sfx")) in
     create_7z_archive ~sevenz_exe ~archive_path ~archive_dir;
     create_7z_sfx ~sfx ~archive_path ~installer_path ~program_title
       ~program_version;
     Ok ())
