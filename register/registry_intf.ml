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

  val add_component :
    ?raise_on_error:bool ->
    t ->
    (module Dkml_install_api.Component_config) ->
    unit
  (** [add_component ?raise_on_error registry component] adds the component to the registry.
      
      Ordinarily if there is an error a process {!exit} is performed. Set
      [raise_on_error] to [true] to raise an {!Invalid_argument} error instead. *)

  val validate :
    ?raise_on_error:bool -> t -> Register_types.install_direction -> unit
  (** [validate ?raise_on_error registry direction] succeeds if and only if all dependencies of all
      [add_component registry] have been themselves added.
        
      Ordinarily if there is an error a process {!exit} is performed. Set
      [raise_on_error] to [true] to raise an {!Invalid_argument} error instead. *)

  val install_eval :
    t ->
    selector:component_selector ->
    f:
      ((module Dkml_install_api.Component_config) ->
      'a Dkml_install_api.Forward_progress.t) ->
    fl:Dkml_install_api.Forward_progress.fatal_logger ->
    'a list Dkml_install_api.Forward_progress.t
  (** [install_eval registry ~f ~fl] iterates through the registry in dependency order
      using component's {!Dkml_install_api.Component_config.install_depends_on} value,
      executing function [f] on each component configuration.
    
      Errors will go to the fatal logger [fl]. *)

  val uninstall_eval :
    t ->
    selector:component_selector ->
    f:
      ((module Dkml_install_api.Component_config) ->
      'a Dkml_install_api.Forward_progress.t) ->
    fl:Dkml_install_api.Forward_progress.fatal_logger ->
    'a list Dkml_install_api.Forward_progress.t
  (** [uninstall_eval registry ~f ~fl] iterates through the registry in reverse
      dependency order using component's {!Dkml_install_api.Component_config.install_depends_on} value,
      executing function [f] on each component configuration.

      Errors will go to the fatal logger [fl]. *)

  (** The module [Private] is meant for internal use only. *)
  module Private : sig
    val reset : unit -> unit
  end
end
