open Dkml_install_register
open Dkml_install_api
open Astring
open Bos
open Os_utils
module StringMap = Map.Make (String)

let ( let* ) = Dkml_install_api.Forward_progress.bind

let patheval_fatal_log ~id s =
  Logs.err (fun l ->
      l "%a %a" Dkml_install_api.Forward_progress.styled_fatal_id id
        Dkml_install_api.Forward_progress.styled_fatal_message s)

let return a = Dkml_install_api.Forward_progress.return (a, patheval_fatal_log)

module Global_context = struct
  type t = {
    global_vars : (string * string) list;
    global_pathonly_vars : (string * string) list;
    default_tmp_dir : Fpath.t;
    reg : Component_registry.t;
  }

  type install_direction = Install | Uninstall

  let create ~install_direction reg =
    let* var_list, _fl =
      let eval =
        match install_direction with
        | Install -> Component_registry.install_eval
        | Uninstall -> Component_registry.uninstall_eval
      in
      eval reg ~selector:All_components ~fl:patheval_fatal_log ~f:(fun cfg ->
          let module Cfg = (val cfg : Component_config) in
          return Cfg.component_name)
    in
    let all_components_var =
      ("components:all", String.concat ~sep:" " var_list)
    in
    return
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

    let* temp_val, _fl =
      Error_handling.map_msg_error_to_progress (OS.Dir.tmp "path_eval_%s")
    in
    let temp_var = ("tmp", Fpath.to_string temp_val) in
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

    return { all_vars = local_vars; all_pathonly_vars = local_pathonly_vars }

  let create global_ctx ~install_direction ~self_component_name ~abi
      ~staging_files_source ~prefix =
    let name_var = ("name", self_component_name) in
    let* temp_val, _fl =
      Error_handling.map_msg_error_to_progress
        (Global_context.tmp_dir global_ctx)
    in
    let temp_var = ("tmp", Fpath.to_string temp_val) in
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
    let eval =
      match install_direction with
      | Global_context.Install -> Component_registry.install_eval
      | Uninstall -> Component_registry.uninstall_eval
    in
    let* self_component_vars, _fl =
      eval global_ctx.reg ~selector:self_selector ~fl:patheval_fatal_log
        ~f:(fun cfg ->
          let module Cfg = (val cfg : Component_config) in
          return
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
    let self_share_vars = List.flatten self_component_vars in
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
    return { all_vars; all_pathonly_vars }

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
    let open Error_handling.Monad_syntax in
    let* orig, _fl =
      Interpreter.create mock_global_ctx ~install_direction:Install
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
    return
      {
        Interpreter.all_vars = orig.all_vars @ extra_pathonly_vars;
        all_pathonly_vars = orig.all_pathonly_vars @ extra_pathonly_vars;
      }
end
