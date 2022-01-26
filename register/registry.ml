open Dkml_install_api

type t = (string, (module Component_config)) Hashtbl.t

let global_registry : t = Hashtbl.create 17

let get () = global_registry

let add_component reg cfg =
  let module Cfg = (val cfg : Component_config) in
  let ( >>= ) = Result.bind in
  Validate.validate (module Cfg) >>= fun () ->
  match Hashtbl.find_opt reg Cfg.component_name with
  | Some _component ->
      Result.error
        (Fmt.str
           "[debe504f] The component named '%s' has already been added to the \
            registry"
           Cfg.component_name)
  | None ->
      Hashtbl.add reg Cfg.component_name cfg;
      Result.ok ()

let toposort reg =
  let vertex_map =
    Hashtbl.to_seq_values reg |> List.of_seq
    |> List.map (fun cfg ->
           let module Cfg = (val cfg : Component_config) in
           (Cfg.component_name, Cfg.depends_on))
  in
  match Tsort.sort vertex_map with
  | Sorted lst ->
      Result.ok
        (List.filter_map
           (fun component_name -> Hashtbl.find_opt reg component_name)
           lst)
  | ErrorCycle lst ->
      Result.error
        Fmt.(
          str "There is a circular dependency chain: %a"
            (list ~sep:(any "->@ ") string)
            lst)

let eval_each ~f lst =
  List.fold_left
    (fun acc cfg -> Result.bind acc (fun () -> f cfg))
    (Result.ok ()) lst

let eval reg ~f = Result.bind (Result.map (eval_each ~f) (toposort reg)) Fun.id

let reverse_eval reg ~f =
  Result.bind
    (Result.map (eval_each ~f) (Result.map List.rev (toposort reg)))
    Fun.id
