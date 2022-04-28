val setup :
  Dkml_package_console_common.program_name ->
  Dkml_package_console_common.package_args ->
  unit

val create_installers :
  Dkml_package_console_common.organization ->
  Dkml_package_console_common.program_name ->
  unit Cmdliner.Term.result
