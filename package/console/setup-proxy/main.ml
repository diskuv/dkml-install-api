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
    the Dune site plugin and ocamlrun.exe.

    We set ["DUNE_OCAML_HARDCODED"] to avoid the Dune 2.9.3 problem at
    https://github.com/ocaml/dune/blob/dea03875affccc0620e902d28fed8d6b4351e112/otherlibs/site/src/helpers.ml#L119:
    {["""
    Not_found
    Raised at Stdlib__string.index_rec in file "string.ml", line 115, characters 19-34
    Called from Sexplib0__Sexp.Printing.index_of_newline in file "src/sexp.ml", line 113, characters 13-47    
    """]}
    or
    {["""
    Not_found
    Raised at Stdlib__string.index_rec in file "string.ml", line 115, characters 19-34
    Called from Stdlib__string.index in file "string.ml" (inlined), line 119, characters 16-42
    Called from Cmdliner_cline.parse_opt_arg in file "cmdliner_cline.ml", line 69, characters 12-30
    Called from Stdlib__sys.getenv_opt in file "stdlib/sys.mlp", line 62, characters 11-21
    Called from Dune_site__Helpers.ocamlpath in file "otherlibs/site/src/helpers.ml", line 119, characters 39-74
    Called from CamlinternalLazy.force_lazy_block in file "camlinternalLazy.ml", line 31, characters 17-27
    Re-raised at CamlinternalLazy.force_lazy_block in file "camlinternalLazy.ml", line 36, characters 4-11
    Called from Dune_site_plugins__Plugins.load_requires in file "otherlibs/site/src/plugins/plugins.ml", line 213, characters 26-56
    Called from Stdlib__list.iter in file "list.ml", line 110, characters 12-15
    Called from Dune_site_plugins__Plugins.load_gen in file "otherlibs/site/src/plugins/plugins.ml", line 204, characters 4-36
    Called from Stdlib__list.iter in file "list.ml", line 110, characters 12-15
    Called from Dkml_install_runner_sites.load_all in file "runner/sites/dkml_install_runner_sites.ml" (inlined), line 20, characters 18-51
    """]}
*)
let spawn_ocamlrun ~ocamlrun_exe ~archive_lib ~lib_ocaml cmd =
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
    let new_env =
      String.Map.add "DUNE_OCAML_HARDCODED"
        (Fpath.to_string archive_lib)
        new_env
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
  let archive_lib = Fpath.(archive_dir / "lib") in
  let lib_ocaml = Fpath.(ocamlrun_dir / "lib" / "ocaml") in
  (* Run the packager setup.bc *)
  let setup_bc = Fpath.(archive_dir / "bin" / "dkml-package-setup.bc") in
  spawn_ocamlrun ~ocamlrun_exe ~archive_lib ~lib_ocaml
    Cmd.(v (Fpath.to_string setup_bc))
