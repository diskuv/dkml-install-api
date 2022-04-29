(* Most of this content is a modification of:
   https://github.com/diskuv/dkml-component-ocamlcompiler/blob/d01c4f78ee1a794dab53b27f7fcb999f0b956f98/src/api/staging-ocamlrun/staging_ocamlrun_api.ml *)

open Bos
open Astring

let is_not_defined name env =
  match String.Map.find name env with
  | None -> true
  | Some "" -> true
  | Some _ -> false

(** [wait_for_user_confirmation_if_popup_terminal] asks the user to press "y"
    if and only if all the following are true: the terminal is a tty, the
    ["CI"] environment variable is not ["true"], and the terminal is on a
    platform that will pop open a new terminal when running the setup (today
    only Windows ABIs are popup terminal platforms).

    Typically this should be used before exiting the program so that the user
    has a chance to see the final messages, especially success or failure.
  *)
let wait_for_user_confirmation_if_popup_terminal host_abi =
  match (OS.Env.opt_var "CI" ~absent:"", Unix.isatty Unix.stdin) with
  | ci, true
    when Dkml_install_api.Context.Abi_v2.is_windows host_abi && ci != "true" ->
      print_newline ();
      print_endline
        (Fmt.str
           "[INFO] Set CI=%a in the environment to skip the confirmation \
            question in future installations."
           Fmt.Dump.string "true");
      (* Sigh. Would just like to wait for a single character "y" rather
          than "y" + ENTER. However no easy OCaml interface to that, and more
          importantly we don't have any discard-prior-keyboard-events API
          on Windows like Unix.tcflush that can ensure the user has had a
          chance to see the final messages (as opposed to accidentally
          pressing a key early in the install process, and having that
          keystroke be interpreted at the end of the installer as confirmation
          that they have read the final messages). *)
      let rec helper () =
        print_newline ();
        print_endline {|Press "y" and ENTER to exit the installer.|};
        match read_line () with
        | "y" ->
            (* 7zip sfx needs to delete the possibly large temporary
               directory it uninstalled, so give user some feedback. *)
            print_endline "Exiting ...";
            ()
        | _ -> helper ()
      in
      helper ()
  | _ -> ()

(** [get_and_remove_path env] finds the first of the ["PATH"] or the ["Path"] environment variable (the latter
    is present sometimes on Windows), and removes the same two environment variables from [env]. *)
let get_and_remove_path env =
  (*

       TODO: STOP DUPLICATING THIS CODE! The canonical source is
       dkml-component-ocamlrun's staging_ocamlrun_api.ml
  *)
  let old_path_as_list =
    match String.Map.find_opt "PATH" env with
    | Some v when v != "" -> [ v ]
    | _ -> (
        match String.Map.find_opt "Path" env with
        | Some v when v != "" -> [ v ]
        | _ -> [])
  in
  let new_env = String.Map.remove "PATH" env in
  let new_env = String.Map.remove "Path" new_env in
  (old_path_as_list, new_env)

(** [spawn_ocamlrun] sets the environment variables needed for
    ocamlrun.exe. *)
let spawn_ocamlrun ~ocamlrun_exe ~host_abi ~lib_ocaml cmd =
  (*

       TODO: STOP DUPLICATING THIS CODE! The canonical source is
       dkml-component-ocamlrun's staging_ocamlrun_api.ml
  *)
  let new_cmd = Cmd.(v (Fpath.to_string ocamlrun_exe) %% cmd) in
  Logs.info (fun m -> m "Running bytecode with: %a" Cmd.pp new_cmd);
  let ( let* ) = Result.bind in
  let sequence =
    let* new_env = OS.Env.current () in
    let old_path_as_list, new_env = get_and_remove_path new_env in
    (* Definitely enable stacktraces *)
    let new_env =
      if is_not_defined "OCAMLRUNPARAM" new_env then
        String.Map.add "OCAMLRUNPARAM" "b" new_env
      else new_env
    in
    (* Handle dynamic loading *)
    let new_env =
      String.Map.add "OCAMLLIB" (Fpath.to_string lib_ocaml) new_env
    in
    (* Handle the early loading of dllunix by ocamlrun *)
    let stublibs = Fpath.(lib_ocaml / "stublibs") in
    let new_env =
      match host_abi with
      | _ when Dkml_install_api.Context.Abi_v2.is_windows host_abi ->
          (* Add lib/ocaml/stublibs to PATH for Win32
             to locate the dllunix.dll *)
          let path_sep = if Sys.win32 then ";" else ":" in
          let new_path_entries =
            [ Fpath.(to_string stublibs) ] @ old_path_as_list
          in
          let new_path = String.concat ~sep:path_sep new_path_entries in
          String.Map.add "PATH" new_path new_env
      | _ when Dkml_install_api.Context.Abi_v2.is_darwin host_abi ->
          (* Add lib/ocaml/stublibs to DYLD_FALLBACK_LIBRARY_PATH for macOS
             to locate the dllunix.so *)
          String.Map.add "DYLD_FALLBACK_LIBRARY_PATH"
            Fpath.(to_string stublibs)
            new_env
      | _
        when Dkml_install_api.Context.Abi_v2.is_linux host_abi
             || Dkml_install_api.Context.Abi_v2.is_android host_abi ->
          (* Add lib/ocaml/stublibs to LD_LIBRARY_PATH for Linux and Android
             to locate the dllunix.so *)
          String.Map.add "LD_LIBRARY_PATH" Fpath.(to_string stublibs) new_env
      | _ -> new_env
    in
    OS.Cmd.run_status ~env:new_env new_cmd
  in
  match sequence with
  | Ok (`Exited 0) ->
      Logs.info (fun l -> l "The command %a ran successfully" Cmd.pp cmd);
      wait_for_user_confirmation_if_popup_terminal host_abi
  | Ok (`Exited c) ->
      Logs.err (fun l -> l "The command %a exited with status %d" Cmd.pp cmd c);
      wait_for_user_confirmation_if_popup_terminal host_abi;
      exit 2
  | Ok (`Signaled c) ->
      Logs.err (fun l ->
          l "The command %a terminated from a signal %d" Cmd.pp cmd c);
      wait_for_user_confirmation_if_popup_terminal host_abi;
      (* https://stackoverflow.com/questions/1101957/are-there-any-standard-exit-status-codes-in-linux/1535733#1535733 *)
      exit (128 + c)
  | Error rmsg ->
      Logs.err (fun l ->
          l "The command %a could not be run due to: %a" Cmd.pp cmd
            Rresult.R.pp_msg rmsg);
      wait_for_user_confirmation_if_popup_terminal host_abi;
      exit 3

let () =
  (* Default logging *)
  let (_ : Dkml_install_api.Log_config.t) =
    Dkml_install_runner.Cmdliner_runner.setup_log None None
  in
  (* Get args, if any.
     If there are no arguments, supply defaults so that there is console
     logging. *)
  let argl = List.tl (Array.to_list Sys.argv) in
  let argl =
    match (Sys.win32, argl) with
    | true, [] ->
        (* Windows does not have a TERM environment variable for auto-detection,
           but color always works in Command Prompt or PowerShell *)
        [ "-v"; "--color=always" ]
    | false, [] -> [ "-v" ]
    | _ -> argl
  in
  let args = Cmd.of_list argl in
  (* Find ocamlrun and ocaml lib *)
  let archive_dir =
    Dkml_install_runner.Cmdliner_runner.enduser_archive_dir ()
  in
  let host_abi =
    Dkml_install_runner.Error_handling.get_ok_or_raise_string
      (Dkml_install_runner.Host_abi.create_v2 ())
  in
  let ocamlrun_dir =
    Fpath.(
      archive_dir / "sg" / "staging-ocamlrun"
      / Dkml_install_api.Context.Abi_v2.to_canonical_string host_abi)
  in
  let ocamlrun_exe = Fpath.(ocamlrun_dir / "bin" / "ocamlrun.exe") in
  let lib_ocaml = Fpath.(ocamlrun_dir / "lib" / "ocaml") in
  (* Run the packager setup.bc with any arguments it needs *)
  let setup_bc = Fpath.(archive_dir / "bin" / "dkml-package-setup.bc") in
  spawn_ocamlrun ~ocamlrun_exe ~host_abi ~lib_ocaml
    Cmd.(v (Fpath.to_string setup_bc) %% args)