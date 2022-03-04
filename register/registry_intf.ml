module type Intf = sig
  type t
  (** The type of the component registry *)

  (** The type of the component selector. Either all components,
      or just the specified components plus all of their dependencies. *)
  type component_selector =
    | All_components
    | Just_named_components_plus_their_dependencies of string list

  val get : unit -> t
  (** Get a reference to the global component registry *)

  val add_component : t -> (module Dkml_install_api.Component_config) -> unit
  (** [add_component registry component] adds the component to the registry *)

  val validate : t -> (unit, string) result
  (** [validate registry] succeeds if and only if all dependencies of all
      [add_component registry] have been themselves added *)

  val eval :
    t ->
    selector:component_selector ->
    f:((module Dkml_install_api.Component_config) -> ('a, string) result) ->
    ('a list, string) result
  (** [eval registry ~f] iterates through the registry in dependency order,
      executing function [f] on each component configuration.
   *)

  val reverse_eval :
    t ->
    selector:component_selector ->
    f:((module Dkml_install_api.Component_config) -> ('a, string) result) ->
    ('a list, string) result
  (** [reverse_eval registry ~f] iterates through the registry in reverse
      dependency order, executing function [f] on each component configuration.
   *)

  (** The module [Private] is meant for internal use only. *)
  module Private : sig
    val reset : unit -> unit
  end
end
