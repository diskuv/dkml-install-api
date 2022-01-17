module type Component_config = Types.Component_config
module Component_registry = Registry

module Private = struct
  let validate = Validate.validate
end