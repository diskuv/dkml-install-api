open Dkml_install_api

let ( >>= ) = Result.bind

type t = (string, (module Component_config)) Hashtbl.t

let global_registry : t = Hashtbl.create 17

let get () = global_registry

let add_component reg cfg =
  let module Cfg = (val cfg : Component_config) in
  match Validate.validate (module Cfg) with
  | Ok () -> (
      match Hashtbl.find_opt reg Cfg.component_name with
      | Some _component ->
          raise
            (Installation_error
               (Fmt.str
                  "[debe504f] The component named '%s' has already been added \
                   to the registry"
                  Cfg.component_name))
      | None ->
          Logs.debug (fun m ->
              m
                "@[Adding component '%s' to the registry with dependencies:@]@ \
                 @[%a@]@"
                Cfg.component_name
                Fmt.(Dump.list string)
                Cfg.depends_on);
          Hashtbl.add reg Cfg.component_name cfg)
  | Error s -> raise (Installation_error s)

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
    (fun acc cfg ->
      acc >>= fun v ->
      match f cfg with
      | Ok v2 -> Result.ok (v2 :: v)
      | Error e -> Result.error e)
    (Result.ok []) lst

let eval reg ~f =
  Result.map (eval_each ~f) (toposort reg) >>= fun res ->
  Result.map List.rev res

let reverse_eval reg ~f =
  Result.map (eval_each ~f) (Result.map List.rev (toposort reg)) >>= fun res ->
  Result.map List.rev res

module Private = struct
  let reset () = Hashtbl.clear global_registry
end
