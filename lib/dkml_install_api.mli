(** Each component must have a configuration module defined with the
    module type [Component_config].
  *)
module type Component_config = sig
  include Types.Component_config
  (** @inline *)
end

(** The [Component_registry] is a global registry of all components that have been
    registered until now.
    
    Component authors should follow this sequence:

    {[
        open Dkml_install_api

        module Component : Component_config = struct
            (** Fill this in *)
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
  val validate : (module Types.Component_config) -> (unit, string) result
end