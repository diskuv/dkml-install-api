module type Intf = sig
  type t
  (** The type of the component registry *)

  val get : unit -> t
  (** Get a reference to the global component registry *)

  val add_component : t -> (module Dkml_install_api.Component_config) -> unit
  (** [add_component registry component] adds the component to the registry *)

  val eval :
    t ->
    f:((module Dkml_install_api.Component_config) -> ('a, string) Result.t) ->
    ('a list, string) Result.t
  (** [eval registry ~f] iterates through the registry in dependency order,
      executing function [f] on each component configuration.
   *)

  val reverse_eval :
    t ->
    f:((module Dkml_install_api.Component_config) -> ('a, string) Result.t) ->
    ('a list, string) Result.t
  (** [reverse_eval registry ~f] iterates through the registry in reverse
      dependency order, executing function [f] on each component configuration.
   *)

  (** The module [Private] is meant for internal use only. *)
  module Private : sig
    val reset : unit -> unit
  end
end
