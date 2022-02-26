type log_config = {
  log_config_style_renderer : Fmt.style_renderer option;
  log_config_level : Logs.level option;
}

let prefix_arg = "prefix"

let staging_files_arg = "staging-files"

let static_files_arg = "static-files"

let opam_context_args = "opam-context"
