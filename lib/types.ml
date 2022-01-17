module type Component_config = sig
  (** [component_name] is the name of the component. It must be lowercase
      alphanumeric; dashes (-) are allowed. *)
  val component_name : string
end
