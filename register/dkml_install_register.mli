include module type of Register_types

(** The [Component_registry] is a global registry of all components that have been
    registered until now.

    Component authors should follow this sequence:

    {[
        open Dkml_install_api

        module Component : Component_config = struct
          include Default_component_config
          let component_name = "...the..component..name..."
          (** Redefine any other values you want to override *)
        end
        let reg = Component_registry.get ()
        let () = Component_registry.add_component reg (module Component : Component_config)
    ]} *)
module Component_registry : sig
  include Registry_intf.Intf
  (** @inline *)
end

(**/**) (* Toggle odoc to not include the definitions that follow. *)

(** The module [Private] is meant for internal use only. *)
module Private : sig
  val validate :
    (module Dkml_install_api.Component_config) -> (unit, string) result
end
