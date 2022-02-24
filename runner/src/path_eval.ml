open Dkml_install_register
open Dkml_install_api
open Astring
open Bos
open Os_utils
module StringMap = Map.Make (String)

module Global_context = struct
  type t = {
    global_vars : (string * string) list;
    global_pathonly_vars : (string * string) list;
    default_tmp_dir : Fpath.t;
  }

  type staging_files_source = Opam_context | Staging_files_dir of string

  (** [absdir_staging_files ~component_name staging_files_source] is
    the [component_name] component's staging-files directory *)
  let absdir_staging_files ~component_name = function
    | Opam_context ->
        Os_utils.absdir_install_files ~component_name Staging Opam_context
    | Staging_files_dir staging_files ->
        Os_utils.absdir_install_files ~component_name Staging
          (Install_files_dir staging_files)

  let create reg ~staging_files_source =
    let component_vars_res =
      Component_registry.eval reg ~f:(fun cfg ->
          let module Cfg = (val cfg : Component_config) in
          Result.ok
            ( Cfg.component_name,
              Cfg.component_name ^ ":share",
              absdir_staging_files ~component_name:Cfg.component_name
                staging_files_source ))
    in
    let share_vars =
      match component_vars_res with
      | Ok var_list ->
          List.map
            (fun (_componentname, varname, varvalue) -> (varname, varvalue))
            var_list
      | Error err -> failwith err
    in
    let all_components_var =
      match component_vars_res with
      | Ok var_list ->
          ( "components:all",
            String.concat ~sep:" "
            @@ List.map
                 (fun (componentname, _varname, _varvalue) -> componentname)
                 var_list )
      | Error err -> failwith err
    in
    {
      global_vars = [ all_components_var ] @ share_vars;
      global_pathonly_vars = share_vars;
      default_tmp_dir = OS.Dir.default_tmp ();
    }

  let global_pathonly_vars { global_pathonly_vars; _ } = global_pathonly_vars

  let global_vars { global_vars; _ } = global_vars

  let tmp_dir { default_tmp_dir; _ } =
    OS.Dir.tmp ~dir:default_tmp_dir "path_eval_%s"
end

module Interpreter = struct
  type t = {
    all_vars : (string * string) list;
    all_pathonly_vars : (string * string) list;
  }

  let create global_ctx ~self_component_name ~prefix =
    let name_var = ("name", self_component_name) in
    let temp_var =
      ( "tmp",
        Fpath.to_string @@ Rresult.R.error_msg_to_invalid_arg
        @@ Global_context.tmp_dir global_ctx )
    in
    let prefix_var = ("prefix", normalize_path prefix) in
    let local_vars = [ name_var; temp_var; prefix_var ] in
    let all_vars =
      List.concat [ Global_context.global_vars global_ctx; local_vars ]
    in
    let all_pathonly_vars =
      List.concat [ Global_context.global_pathonly_vars global_ctx; local_vars ]
    in
    { all_vars; all_pathonly_vars }

  let rec eval_helper text = function
    | [] -> text
    | (varname, varvalue) :: tl ->
        let search_for = "%{" ^ varname ^ "}%" in
        let new_text =
          String.(concat ~sep:varvalue (cuts ~empty:true ~sep:search_for text))
        in
        eval_helper new_text tl

  let eval { all_vars; _ } expression = eval_helper expression all_vars

  let path_eval { all_pathonly_vars; _ } expression =
    string_to_norm_fpath @@ eval_helper expression all_pathonly_vars
end

(** {1 Tests} *)

let mock_default_tmp_dir = OS.Dir.default_tmp ()

let mock_global_ctx =
  let global_pathonly_vars =
    [
      ( "ocamlrun:share",
        Global_context.absdir_staging_files ~component_name:"ocamlrun"
          (Staging_files_dir "/test/staging-files") );
    ]
  in
  {
    Global_context.global_pathonly_vars;
    global_vars =
      [ ("components:all", "ocamlrun component_under_test") ]
      @ global_pathonly_vars;
    default_tmp_dir = mock_default_tmp_dir;
  }

let interpreter () =
  Interpreter.create mock_global_ctx ~self_component_name:"component_under_test"
    ~prefix:"/test/prefix"

let%test "%{components:all}% are all the available components" =
  let r = Interpreter.eval (interpreter ()) "%{components:all}%" in
  Fmt.pr "[inline test debug] %s = %s@\n" "%{components:all}%" r;
  r = "ocamlrun component_under_test"

let%test "%{components:all}% is not available with path_eval" =
  let r = Interpreter.path_eval (interpreter ()) "%{components:all}%" in
  r = Fpath.v "%{components:all}%"

let%test "%{tmp}% is a prefix of the temp directory" =
  let r = Interpreter.path_eval (interpreter ()) "%{tmp}%" in
  Fpath.(is_prefix mock_default_tmp_dir r)

let%test "%{name}% is the component under test" =
  let r = Interpreter.path_eval (interpreter ()) "%{name}%" in
  r = Fpath.v "component_under_test"

let%test "%{prefix}% is the installation prefix" =
  let r = Interpreter.path_eval (interpreter ()) "%{prefix}%" in
  Fpath.(compare (v "/test/prefix") r) = 0

let%test "%{prefix}%/bin is the bin/ folder under the installation prefix" =
  let r = Interpreter.path_eval (interpreter ()) "%{prefix}%/bin" in
  Fpath.(compare (v "/test/prefix/bin") r) = 0

let%test "%{ocamlrun:share}% is the staging prefix of the ocamlrun component" =
  let r = Interpreter.path_eval (interpreter ()) "%{ocamlrun:share}%" in
  Fmt.pr "[inline test debug] %s = %a@\n" "%{ocamlrun:share}%" Fpath.pp r;
  Fpath.(compare (v "/test/staging-files/ocamlrun") r) = 0
