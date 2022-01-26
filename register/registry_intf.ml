module type Intf = sig
  type t
  (** The type of the component registry *)

  val get : unit -> t
  (** Get a reference to the global component registry *)

  val add_component :
    t -> (module Dkml_install_api.Component_config) -> (unit, string) Result.t
  (** [add_component registry component] adds the component to the registry *)

  val eval :
    t ->
    f:((module Dkml_install_api.Component_config) -> (unit, string) Result.t) ->
    (unit, string) Result.t
  (** [eval registry ~f] iterates through the registry in dependency order,
      executing function [f] on each component configuration.
   *)

  val reverse_eval :
    t ->
    f:((module Dkml_install_api.Component_config) -> (unit, string) Result.t) ->
    (unit, string) Result.t
  (** [reverse_eval registry ~f] iterates through the registry in reverse
      dependency order, executing function [f] on each component configuration.
   *)
end
