module type Plugin_config = Types.Plugin_config

module Private = struct
  let validate = Validate.validate
end