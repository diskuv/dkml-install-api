open Types
open Astring

let validate (module Cfg : Plugin_config) =
  let alphanumeric c =
    (c >= 'a' && c <= 'z') || (c >= '0' && c <= '9') || c = '-'
  in
  if String.for_all alphanumeric Cfg.plugin_name then Result.ok ()
  else
    Result.error
      (Fmt.str
         "[19c415af]: The plugin_name must be alphanumeric with only dashes \
          (-) allowed. Instead the plugin name was: %s"
         Cfg.plugin_name)
