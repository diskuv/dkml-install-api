open Dkml_package_console_common

let organization =
  {
    Author_types.legal_name = "Example LLC";
    common_name_full = "Example Org";
    common_name_camel_case_nospaces = "ExampleOrg";
    common_name_kebab_lower_case = "example-org";
  }

let program_name =
  {
    Author_types.name_full = "Example Program";
    name_camel_case_nospaces = "ExampleProgram";
    name_kebab_lower_case = "example-program";
    installation_prefix_camel_case_nospaces_opt = None;
    installation_prefix_kebab_lower_case_opt = None;
  }

let program_version = "0.0.0-dev"
let program_assets = { Author_types.logo_icon_32x32_opt = None }

let program_info =
  {
    Author_types.url_info_about_opt = None;
    url_update_info_opt = None;
    help_link_opt = None;
    estimated_byte_size_opt = None;
    windows_language_code_id_opt = None;
    embeds_32bit_uninstaller = false;
    embeds_64bit_uninstaller = false;
  }
