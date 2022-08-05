let organization =
  {
    Dkml_package_console_common.legal_name = "Example LLC";
    common_name_full = "Example Org";
    common_name_camel_case_nospaces = "ExampleOrg";
    common_name_kebab_lower_case = "example-org";
  }

let program_name =
  {
    Dkml_package_console_common.name_full = "Example Program";
    name_camel_case_nospaces = "ExampleProgram";
    name_kebab_lower_case = "example-program";
    installation_prefix_camel_case_nospaces_opt = None;
    installation_prefix_kebab_lower_case_opt = None;
  }

let program_assets = { Dkml_package_console_common.logo_icon_32x32_opt = None }

let program_info =
  {
    Dkml_package_console_common.url_info_about_opt = None;
    url_update_info_opt = None;
    help_link_opt = None;
    estimated_byte_size_opt = None;
    windows_language_code_id_opt = None;
  }
