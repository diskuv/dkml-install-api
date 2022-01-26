module type Intf = sig
  type t
  (** The type of the component registry *)

  val get : unit -> t
  (** Get a reference to the global component registry *)

  (** [add_component registry component] adds the component to the registry *)
  val add_component : t -> (module Dkml_install_api.Component_config) -> (unit, string) Result.t

  (** [iter registry ~f] iterates through the registry, executing function [f] on each component
      name and configuration.
   *)
  val iter : t -> f:(string -> (module Dkml_install_api.Component_config) -> unit) -> unit
end
