open Bos

let ( >>= ) = Result.bind

(** [string_to_fpath str] converts [str] into a [Fpath.t]. On Windows the
    [str] is normalized to a regular Windows file path (ex. backslashes). *)
let string_to_norm_fpath str =
  match Fpath.of_string str with Ok p -> p | Error (`Msg e) -> failwith e

(** [normalize_path] normalizes a path so on Windows it is a regular
    Windows path with backslashes. *)
let normalize_path str = Fpath.(to_string (string_to_norm_fpath str))

let copy_dir src dst =
  let cp rel success =
    Logs.on_error ~pp:Rresult.R.pp_msg ~use:(fun _ -> false)
    @@
    if not success then (* no more copying if we had an error *)
      Result.ok false
    else
      let src = Fpath.(src // rel) and dst = Fpath.(dst // rel) in
      OS.Path.Mode.get src >>= fun mode ->
      OS.File.read src >>= fun data ->
      OS.Dir.create (Fpath.parent dst) >>= fun _ ->
      OS.File.write ~mode dst data >>= fun () -> Result.ok true
  in
  OS.Path.fold cp true [ src ] >>= function
  | true -> Result.ok ()
  | false ->
      Rresult.R.error_msgf "Failed to copy the directory from %a to %a" Fpath.pp
        src Fpath.pp dst

type install_files_source = Opam_context | Install_files_dir of string

type install_files_type = Staging | Static

(** [absdir_install_files ~component_name install_files_type install_files_source] is
    the [component_name] component's static-files or staging-files directory
    for Staging or Static [install_files_type], respectively *)
let absdir_install_files ~component_name install_files_type = function
  | Opam_context ->
      let opam_switch_prefix = OS.Env.opt_var "OPAM_SWITCH_PREFIX" ~absent:"" in
      if opam_switch_prefix = "" then
        failwith
          "When using --opam-context the OPAM_SWITCH_PREFIX environment \
           variable must be defined by evaluating the `opam env` command.";
      let stem =
        match install_files_type with
        | Staging -> "staging-files"
        | Static -> "static-files"
      in
      Fpath.(
        to_string
        @@ string_to_norm_fpath opam_switch_prefix
           / "share"
           / ("dkml-component-" ^ component_name)
           / stem)
  | Install_files_dir install_files ->
      Fpath.(to_string @@ (string_to_norm_fpath install_files / component_name))
