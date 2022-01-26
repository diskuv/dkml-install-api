module type Component_config = sig
  (** [component_name] is the name of the component. It must be lowercase
      alphanumeric; dashes (-) are allowed. *)
  val component_name : string

  (** [depends_on] are the components, if any, that this component depends on.

      Dependencies will be installed in order and uninstalled in reverse
      order. *)
  val depends_on: string list
end
