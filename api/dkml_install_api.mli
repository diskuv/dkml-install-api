(** Each component must have a configuration module defined with the
    module type [Component_config].
  *)
module type Component_config = sig
  include Types.Component_config
  (** @inline *)
end

module Noop_component_config : Component_config
