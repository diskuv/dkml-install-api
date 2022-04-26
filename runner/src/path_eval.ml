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
    reg : Component_registry.t;
  }

  let create reg =
    let all_component_vars_res =
      Component_registry.eval reg ~selector:All_components ~f:(fun cfg ->
          let module Cfg = (val cfg : Component_config) in
          Result.ok Cfg.component_name)
    in
    let all_components_var =
      match all_component_vars_res with
      | Ok var_list -> ("components:all", String.concat ~sep:" " var_list)
      | Error err -> raise (Installation_error err)
    in
    {
      global_vars = [ all_components_var ];
      global_pathonly_vars = [];
      default_tmp_dir = OS.Dir.default_tmp ();
      reg;
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

  let create_minimal ~self_component_name ~abi ~staging_files_source ~prefix =
    let name_var = ("name", self_component_name) in
    let temp_var =
      ( "tmp",
        Fpath.to_string @@ Rresult.R.error_msg_to_invalid_arg
        @@ OS.Dir.tmp "path_eval_%s" )
    in
    let prefix_var = ("prefix", Fpath.to_string prefix) in
    let current_share_generic_var =
      ( "_:share-generic",
        Fpath.to_string
          (Path_location.absdir_staging_files
             ~component_name:self_component_name ~abi_selector:Generic
             staging_files_source) )
    in
    let current_share_arch_var =
      ( "_:share-abi",
        Fpath.to_string
          (Path_location.absdir_staging_files
             ~component_name:self_component_name ~abi_selector:(Abi abi)
             staging_files_source) )
    in
    let local_pathonly_vars =
      [
        temp_var; prefix_var; current_share_generic_var; current_share_arch_var;
      ]
    in
    let local_vars = [ name_var ] @ local_pathonly_vars in

    { all_vars = local_vars; all_pathonly_vars = local_pathonly_vars }

  let create global_ctx ~self_component_name ~abi ~staging_files_source ~prefix
      =
    let name_var = ("name", self_component_name) in
    let temp_var =
      ( "tmp",
        Fpath.to_string @@ Rresult.R.error_msg_to_invalid_arg
        @@ Global_context.tmp_dir global_ctx )
    in
    let prefix_var = ("prefix", Fpath.to_string prefix) in
    let current_share_generic_var =
      ( "_:share-generic",
        Fpath.to_string
          (Path_location.absdir_staging_files
             ~component_name:self_component_name ~abi_selector:Generic
             staging_files_source) )
    in
    let current_share_abi_var =
      ( "_:share-abi",
        Fpath.to_string
          (Path_location.absdir_staging_files
             ~component_name:self_component_name ~abi_selector:(Abi abi)
             staging_files_source) )
    in
    let local_pathonly_vars =
      [ temp_var; prefix_var; current_share_generic_var; current_share_abi_var ]
    in
    let local_vars = [ name_var ] @ local_pathonly_vars in

    (* Only the self component plus its dependencies will be interpreted *)
    let self_selector =
      Component_registry.Just_named_components_plus_their_dependencies
        [ self_component_name ]
    in
    let self_component_vars_res =
      Component_registry.eval global_ctx.reg ~selector:self_selector
        ~f:(fun cfg ->
          let module Cfg = (val cfg : Component_config) in
          Result.ok
            [
              ( Cfg.component_name ^ ":share-generic",
                Fpath.to_string
                  (Path_location.absdir_staging_files
                     ~component_name:Cfg.component_name ~abi_selector:Generic
                     staging_files_source) );
              ( Cfg.component_name ^ ":share-abi",
                Fpath.to_string
                  (Path_location.absdir_staging_files
                     ~component_name:Cfg.component_name ~abi_selector:(Abi abi)
                     staging_files_source) );
            ])
    in
    let self_share_vars =
      List.flatten
        (Error_handling.get_ok_or_raise_string self_component_vars_res)
    in

    let all_vars =
      List.concat
        [ Global_context.global_vars global_ctx; local_vars; self_share_vars ]
    in
    let all_pathonly_vars =
      List.concat
        [
          Global_context.global_pathonly_vars global_ctx;
          local_pathonly_vars;
          self_share_vars;
        ]
    in
    { all_vars; all_pathonly_vars }

  let first_expression = Str.regexp {|.*\(%{[^}]*}%\)|}

  let validate_eval text varnames =
    if Str.string_match first_expression text 0 then
      failwith
        (Fmt.str
           "There was at least one unresolved expression: %s. Only the \
            following components are visible: %a"
           (Str.matched_group 1 text)
           Fmt.(Dump.list string)
           varnames)
    else text

  let rec eval_helper ~valid_varnames text = function
    | [] -> validate_eval text valid_varnames
    | (varname, varvalue) :: tl ->
        let search_for = "%{" ^ varname ^ "}%" in
        let new_text =
          String.(concat ~sep:varvalue (cuts ~empty:true ~sep:search_for text))
        in
        eval_helper ~valid_varnames new_text tl

  let eval { all_vars; _ } expression =
    eval_helper ~valid_varnames:(List.map fst all_vars) expression all_vars

  let path_eval { all_pathonly_vars; _ } expression =
    string_to_norm_fpath
    @@ eval_helper
         ~valid_varnames:(List.map fst all_pathonly_vars)
         expression all_pathonly_vars
end

module Private = struct
  let mock_default_tmp_dir = OS.Dir.default_tmp ()

  let mock_staging_files_sources =
    Path_location.Staging_files_dir (Fpath.v "/test/staging-files")

  let mock_global_ctx =
    {
      Global_context.global_pathonly_vars = [];
      global_vars = [ ("components:all", "ocamlrun component_under_test") ];
      default_tmp_dir = mock_default_tmp_dir;
      reg = Component_registry.get ();
    }

  let mock_interpreter () =
    let orig =
      Interpreter.create mock_global_ctx
        ~self_component_name:"component_under_test" ~abi:Windows_x86
        ~staging_files_source:mock_staging_files_sources
        ~prefix:(Fpath.v "/test/prefix")
    in
    let extra_pathonly_vars =
      [
        ( "ocamlrun:share-generic",
          Fpath.to_string
            (Path_location.absdir_staging_files ~component_name:"ocamlrun"
               ~abi_selector:Generic mock_staging_files_sources) );
        ( "ocamlrun:share-abi",
          Fpath.to_string
            (Path_location.absdir_staging_files ~component_name:"ocamlrun"
               ~abi_selector:(Abi Windows_x86) mock_staging_files_sources) );
      ]
    in
    {
      Interpreter.all_vars = orig.all_vars @ extra_pathonly_vars;
      all_pathonly_vars = orig.all_pathonly_vars @ extra_pathonly_vars;
    }
end