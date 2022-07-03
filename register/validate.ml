open Dkml_install_api
open Astring

let validate (module Cfg : Component_config) =
  let alphanumeric c =
    (c >= 'a' && c <= 'z') || (c >= '0' && c <= '9') || c = '-'
  in
  if String.for_all alphanumeric Cfg.component_name then Ok ()
  else
    Error
      (Fmt.str
         "[19c415af]: The component_name must be alphanumeric with only dashes \
          (-) allowed. Instead the component name was: %s"
         Cfg.component_name)
