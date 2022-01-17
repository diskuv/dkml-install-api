module type Intf = sig
  type t
  (** The type of the component registry *)

  val get : unit -> t
  (** Get a reference to the global component registry *)

  (** [add_component registry component] adds the component to the registry *)
  val add_component : t -> (module Types.Component_config) -> (unit, string) Result.t
end
