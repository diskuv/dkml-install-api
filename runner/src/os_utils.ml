open Bos
open Error_handling
open Error_handling.Monad_syntax

(** [string_to_fpath str] converts [str] into a [Fpath.t]. On Windows the
    [str] is normalized to a regular Windows file path (ex. backslashes). *)
let string_to_norm_fpath str =
  match Fpath.of_string str with Ok p -> p | Error (`Msg e) -> failwith e

(** [normalize_path] normalizes a path so on Windows it is a regular
    Windows path with backslashes. *)
let normalize_path str = Fpath.(to_string (string_to_norm_fpath str))

let copy_dir src dst =
  let raise_fold_error fpath result =
    Rresult.R.error_msgf
      "@[A copy directory operation errored out while visiting %a.@]@,\
       @[  @[%a@]@]" Fpath.pp fpath
      (Rresult.R.pp
         ~ok:(Fmt.any "<unknown copydir problem>")
         ~error:Rresult.R.pp_msg)
      result
  in
  let cp rel = function
    | Error _ as e ->
        (* no more copying if we had an error *)
        e
    | Ok () ->
        let src = Fpath.(src // rel) and dst = Fpath.(dst // rel) in
        let* mode = map_rresult_error_to_string @@ OS.Path.Mode.get src in
        let* data = map_rresult_error_to_string @@ OS.File.read src in
        let* (_ : bool) =
          map_rresult_error_to_string @@ OS.Dir.create (Fpath.parent dst)
        in
        let+ () = map_rresult_error_to_string @@ OS.File.write ~mode dst data in
        ()
  in
  map_rresult_error_to_string
  @@ OS.Path.fold ~err:raise_fold_error cp (Result.ok ()) [ src ]
  >>= function
  | Ok () -> Result.ok ()
  | Error s ->
      Result.error
        (Fmt.str
           "@[@[Failed to copy the directory@]@[@ from %a@]@[@ to %a@]@ .@]@ \
            @[%s@]"
           Fpath.pp src Fpath.pp dst s)

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
