(* Most of this content is a modification of:
   https://github.com/diskuv/dkml-component-ocamlcompiler/blob/d01c4f78ee1a794dab53b27f7fcb999f0b956f98/src/api/staging-ocamlrun/staging_ocamlrun_api.ml *)

open Bos
open Astring

let is_not_defined name env =
  match String.Map.find name env with
  | None -> true
  | Some "" -> true
  | Some _ -> false

(** [spawn_ocamlrun] sets the environment variables needed for
    ocamlrun.exe. *)
let spawn_ocamlrun ~ocamlrun_exe ~lib_ocaml cmd =
  let new_cmd = Cmd.(v (Fpath.to_string ocamlrun_exe) %% cmd) in
  Logs.info (fun m -> m "Running bytecode with: %a" Cmd.pp new_cmd);
  let ( let* ) = Result.bind in
  let sequence =
    let* new_env = OS.Env.current () in
    let new_env =
      if is_not_defined "OCAMLRUNPARAM" new_env then
        String.Map.add "OCAMLRUNPARAM" "b" new_env
      else new_env
    in
    let new_env =
      String.Map.add "OCAMLLIB" (Fpath.to_string lib_ocaml) new_env
    in
    OS.Cmd.run_status ~env:new_env new_cmd
  in
  match sequence with
  | Ok (`Exited 0) ->
      Logs.info (fun l -> l "The command %a ran successfully" Cmd.pp cmd)
  | Ok (`Exited c) ->
      Logs.err (fun l -> l "The command %a exited with status %d" Cmd.pp cmd c);
      exit 2
  | Ok (`Signaled c) ->
      Logs.err (fun l ->
          l "The command %a terminated from a signal %d" Cmd.pp cmd c);
      (* https://stackoverflow.com/questions/1101957/are-there-any-standard-exit-status-codes-in-linux/1535733#1535733 *)
      exit (128 + c)
  | Error rmsg ->
      Logs.err (fun l ->
          l "The command %a could not be run due to: %a" Cmd.pp cmd
            Rresult.R.pp_msg rmsg);
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
  Fmt.epr "Arg1 (before): %a@\n" Fmt.(Dump.list string) argl;
  let argl =
    match (Sys.win32, argl) with
    | true, [] ->
      (* Windows does not have a TERM environment variable for auto-detection,
         but color always works in Command Prompt or PowerShell *)
      [ "-v"; "--color=always" ]
    | false, [] -> [ "-v" ]
    | _ -> argl
  in
  Fmt.epr "Arg1 (after): %a@\n" Fmt.(Dump.list string) argl;
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
  spawn_ocamlrun ~ocamlrun_exe ~lib_ocaml
    Cmd.(v (Fpath.to_string setup_bc) %% args)
