(** Each plugin must have a configuration module defined with the
    module type [Plugin_config].
  *)
module type Plugin_config = sig
  (** [plugin_name] is the name of the plugin. It must be lowercase
      alphanumeric; dashes (-) are allowed. *)
  val plugin_name : string
end
