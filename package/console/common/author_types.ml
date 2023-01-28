type build_info = {
  package_name : string;
}

type program_name = {
  name_full : string;
  name_camel_case_nospaces : string;
  name_kebab_lower_case : string;
  installation_prefix_camel_case_nospaces_opt : string option;
  installation_prefix_kebab_lower_case_opt : string option;
}

type organization = {
  legal_name : string;
  common_name_full : string;
  common_name_camel_case_nospaces : string;
  common_name_kebab_lower_case : string;
}

type program_assets = { logo_icon_32x32_opt : string option }

type program_info = {
  url_info_about_opt : string option;
  url_update_info_opt : string option;
  help_link_opt : string option;
  estimated_byte_size_opt : int64 option;
  windows_language_code_id_opt : int option;
  embeds_32bit_uninstaller : bool;
  embeds_64bit_uninstaller : bool;
}
