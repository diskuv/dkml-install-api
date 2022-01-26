open Dkml_install_api

let global_registry : (string, (module Component_config)) Hashtbl.t =
  Hashtbl.create 17

type t = (string, (module Component_config)) Hashtbl.t

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

let iter reg ~f = Hashtbl.iter f reg
