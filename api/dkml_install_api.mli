(** Each component must have a configuration module defined with the
    module type [Component_config] *)
module type Component_config = sig
  include Types.Component_config
  (** @inline *)
end

(** Default values for a subset of the module type [Component_config].

    You {e should} [include Default_component_config] in any of your
    components so that your component can be future-proof against
    changes in the [Component_config] signature.
  *)
module Default_component_config : sig
   include Types.Component_config_defaultable
   (** @inline *)
end
