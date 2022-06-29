open Dkml_install_api

let ( let* ) = Forward_progress.bind

let ( let+ ) r f = Forward_progress.map f r

let return = Forward_progress.return

type t = (string, (module Component_config)) Hashtbl.t

type component_selector =
  | All_components
  | Just_named_components_plus_their_dependencies of string list

let global_registry : t = Hashtbl.create 17

let get () = global_registry

let on_error s = function
  | Some true -> raise (Invalid_argument s)
  | _ ->
      prerr_endline s;
      exit
        (Forward_progress.Exit_code.to_int_exitcode Exit_unrecoverable_failure)

let add_component ?raise_on_error reg cfg =
  let module Cfg = (val cfg : Component_config) in
  match Validate.validate (module Cfg) with
  | Ok () -> (
      match Hashtbl.find_opt reg Cfg.component_name with
      | Some _component ->
          on_error
            (Fmt.str
               "FATAL [debe504f]. The component named '%s' has already been \
                added to the registry"
               Cfg.component_name)
            raise_on_error
      | None ->
          Logs.debug (fun m ->
              m
                "@[Adding component '%s' to the registry with dependencies:@]@ \
                 @[%a@]"
                Cfg.component_name
                Fmt.(Dump.list string)
                Cfg.depends_on);
          Hashtbl.add reg Cfg.component_name cfg)
  | Error s -> on_error (Fmt.str "FATAL [7c039d7e]. %s" s) raise_on_error

let validate ?raise_on_error reg =
  Hashtbl.to_seq_values reg |> List.of_seq
  |> List.iter (fun cfg ->
         let module Cfg = (val cfg : Component_config) in
         List.iter
           (fun dependency ->
             if Hashtbl.mem reg dependency then ()
             else
               let msg =
                 Fmt.str
                   "FATAL [14b63c08]. The component '%s' declares a dependency \
                    on '%s' but that dependency is not available as a plugin. \
                    Check the following in order: 1) Has `dkml-component-%s` \
                    been added as an Opam (or findlib) dependency? 2) Does \
                    `dkml-component-%s` call [Registry.add_component] using \
                    [component_name=%a]? 3) Is the PLUGIN_NAME in dune's \
                    `(plugin (name PLUGIN_NAME) ...)` unique across all plugin \
                    name and across all library names in the Opam switch (or \
                    findlib path)?"
                   Cfg.component_name dependency dependency dependency
                   Fmt.Dump.string dependency
               in
               on_error msg raise_on_error)
           Cfg.depends_on)

let toposort reg ~selector ~fl =
  let vertex_map =
    Hashtbl.to_seq_values reg |> List.of_seq
    |> List.map (fun cfg ->
           let module Cfg = (val cfg : Component_config) in
           (Cfg.component_name, Cfg.depends_on))
  in
  let+ tsorted_all =
    match Tsort.sort vertex_map with
    | Sorted lst ->
        return
          ( List.filter_map
              (fun component_name -> Hashtbl.find_opt reg component_name)
              lst,
            fl )
    | ErrorCycle lst ->
        fl ~id:"2b217eea"
          Fmt.(
            str "There is a circular dependency chain: %a"
              (list ~sep:(any "->@ ") string)
              lst);
        Halted_progress Exit_unrecoverable_failure
  in
  match selector with
  | All_components -> tsorted_all
  | Just_named_components_plus_their_dependencies named_components ->
      let tsorted_all_names =
        List.map
          (fun cfg ->
            let module Cfg = (val cfg : Component_config) in
            Cfg.component_name)
          tsorted_all
      in
      (* visit each named component and each of their dependencies *)
      let named_components_plus_dependencies =
        let visited = Hashtbl.create (List.length tsorted_all) in
        let rec walk_each_named_component = function
          | [] -> ()
          | hd :: tl ->
              let rec visit_dep_graph cfg_name =
                match Hashtbl.find_opt reg cfg_name with
                | Some cfg ->
                    let module Cfg = (val cfg : Component_config) in
                    (* theoretically we don't have to check for cycles since
                       we used topological sort. however `reg` is a mutable
                       global and subject to race conditions, so double-check for
                       cycles *)
                    if not (Hashtbl.mem visited cfg_name) then (
                      Hashtbl.add visited cfg_name ();
                      List.iter
                        (fun cfg_name' -> visit_dep_graph cfg_name')
                        Cfg.depends_on)
                | None -> ()
              in
              visit_dep_graph hd;
              walk_each_named_component tl
        in
        walk_each_named_component named_components;
        visited
      in
      (* order `named_components_plus_dependencies` in topological order *)
      List.filter_map
        (fun cfg_name ->
          if Hashtbl.mem named_components_plus_dependencies cfg_name then
            Hashtbl.find_opt reg cfg_name
          else None)
        tsorted_all_names

let eval_each ~f ~fl lst =
  List.fold_left
    (fun acc cfg ->
      let* v, _fl = acc in
      match f cfg with
      | Dkml_install_api.Forward_progress.Continue_progress (v2, fl) ->
          return (v2 :: v, fl)
      | Halted_progress v -> Halted_progress v
      | Completed -> Completed)
    (return ([], fl))
    lst

let eval reg ~selector ~f ~fl =
  let* res, _fl =
    Forward_progress.map (eval_each ~f ~fl) (toposort ~selector ~fl reg)
  in
  Forward_progress.map List.rev res

let reverse_eval reg ~selector ~f ~fl =
  let* res, _fl =
    Forward_progress.map (eval_each ~f ~fl)
      (Forward_progress.map List.rev (toposort ~selector ~fl reg))
  in
  Forward_progress.map List.rev res

module Private = struct
  let reset () = Hashtbl.clear global_registry
end
