open Dkml_install_register
open Dkml_install_api
open Astring
open Bos
module StringMap = Map.Make (String)

(** [string_to_fpath str] converts [str] into a [Fpath.t]. On Windows the
    [str] is normalized to a regular Windows file path (ex. backslashes). *)
let string_to_norm_fpath str =
  match Fpath.of_string str with Ok p -> p | Error (`Msg e) -> failwith e

module Global_context = struct
  type t = { share_vars : (string * string) list; default_tmp_dir : Fpath.t }

  type staging_files_source = Opam_context | Staging_files_dir of string

  (** [absdir_staging_files ~component_name staging_files_source] is
    the [component_name] component's staging-files directory *)
  let absdir_staging_files ~component_name = function
    | Opam_context ->
        let opam_switch_prefix =
          OS.Env.opt_var "OPAM_SWITCH_PREFIX" ~absent:""
        in
        if opam_switch_prefix = "" then
          failwith
            "When using --opam-context the OPAM_SWITCH_PREFIX environment \
             variable must be defined by evaluating the `opam env` command.";
        Fpath.(
          to_string
          @@ string_to_norm_fpath opam_switch_prefix
             / "share"
             / ("dkml-component-" ^ component_name)
             / "staging-files")
    | Staging_files_dir staging_files ->
        Fpath.(
          to_string @@ (string_to_norm_fpath staging_files / component_name))

  let create reg ~staging_files_source =
    let share_vars_res =
      Component_registry.eval reg ~f:(fun cfg ->
          let module Cfg = (val cfg : Component_config) in
          Result.ok
            ( Cfg.component_name ^ ":share",
              absdir_staging_files ~component_name:Cfg.component_name
                staging_files_source ))
    in
    let share_vars =
      match share_vars_res with
      | Ok var_list -> var_list
      | Error err -> failwith err
    in
    { share_vars; default_tmp_dir = OS.Dir.default_tmp () }

  let share_vars { share_vars; _ } = share_vars

  let tmp_dir { default_tmp_dir; _ } =
    OS.Dir.tmp ~dir:default_tmp_dir "path_eval_%s"
end

module Interpreter = struct
  type t = { all_vars : (string * string) list }

  let create global_ctx ~self_component_name ~prefix =
    let name_var = ("name", self_component_name) in
    let temp_var =
      ( "tmp",
        Fpath.to_string @@ Rresult.R.error_msg_to_invalid_arg
        @@ Global_context.tmp_dir global_ctx )
    in
    let prefix_var =
      ("prefix", Fpath.to_string @@ string_to_norm_fpath prefix)
    in
    let all_vars_mp =
      List.concat
        [
          Global_context.share_vars global_ctx;
          [ name_var; temp_var; prefix_var ];
        ]
      |> List.to_seq |> StringMap.of_seq
    in
    { all_vars = StringMap.to_seq all_vars_mp |> List.of_seq }

  let eval { all_vars } expression =
    let rec eval_helper text = function
      | [] -> text
      | (varname, varvalue) :: tl ->
          let search_for = "%{" ^ varname ^ "}%" in
          let new_text =
            String.(
              concat ~sep:varvalue (cuts ~empty:true ~sep:search_for text))
          in
          eval_helper new_text tl
    in
    eval_helper expression all_vars
end

(** {1 Tests} *)

let mock_default_tmp_dir = OS.Dir.default_tmp ()

let mock_global_ctx =
  {
    Global_context.share_vars =
      [
        ( "ocamlrun:share",
          Global_context.absdir_staging_files ~component_name:"ocamlrun"
            (Staging_files_dir "/test/staging-files") );
      ];
    default_tmp_dir = mock_default_tmp_dir;
  }

let interpreter () =
  Interpreter.create mock_global_ctx ~self_component_name:"component_under_test"
    ~prefix:"/test/prefix"

let%test "%{tmp}% is a prefix of the temp directory" =
  let r = Interpreter.eval (interpreter ()) "%{tmp}%" in
  Fpath.(is_prefix mock_default_tmp_dir (v r))

let%test "%{name}% is the component under test" =
  let r = Interpreter.eval (interpreter ()) "%{name}%" in
  r = "component_under_test"

let%test "%{prefix}% is the installation prefix" =
  let r = Interpreter.eval (interpreter ()) "%{prefix}%" in
  Fpath.(compare (v "/test/prefix") (v r)) = 0

let%test "%{prefix}%/bin is the bin/ folder under the installation prefix" =
  let r = Interpreter.eval (interpreter ()) "%{prefix}%/bin" in
  Fpath.(compare (v "/test/prefix/bin") (v r)) = 0

let%test "%{ocamlrun:share}% is the staging prefix of the ocamlrun component" =
  let r = Interpreter.eval (interpreter ()) "%{ocamlrun:share}%" in
  Fmt.pr "[inline test debug] %s = %s@\n" "%{ocamlrun:share}%" r;
  Fpath.(compare (v "/test/staging-files/ocamlrun") (v r)) = 0
