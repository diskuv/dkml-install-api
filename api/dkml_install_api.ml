module type Component_config = Types.Component_config

module Noop_component_config = struct
  let component_name = "no-op"
  let depends_on = []
end
