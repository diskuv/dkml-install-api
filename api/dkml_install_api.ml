open Cmdliner

module type Component_config = Types.Component_config

let administrator =
  if Sys.win32 then "Administrator privileges" else "root permissions"

module Default_component_config = struct
  let depends_on = []

  let install_user_subcommand ~component_name ~subcommand_name ~setup_t =
    let doc =
      Fmt.str
        "Install the component '%s' except the parts, if any, that need %s"
        component_name administrator
    in
    let cmd =
      ( setup_t,
        Term.info subcommand_name ~sdocs:Manpage.s_common_options ~doc )
    in
    Result.ok cmd

  let uninstall_user_subcommand ~component_name ~subcommand_name ~setup_t =
    let doc =
      Fmt.str
        "Uninstall the component '%s' except the parts, if any, that need %s"
        component_name administrator
    in
    let cmd =
      ( setup_t,
        Term.info subcommand_name ~sdocs:Manpage.s_common_options ~doc )
    in
    Result.ok cmd

  let needs_install_admin () = false

  let needs_uninstall_admin () = false

  let install_admin_subcommand ~component_name ~subcommand_name ~setup_t =
    let doc =
      Fmt.str "Install the parts of the component '%s' that need %s"
        component_name administrator
    in
    let cmd =
      ( setup_t,
        Term.info subcommand_name ~sdocs:Manpage.s_common_options ~doc )
    in
    Result.ok cmd

  let uninstall_admin_subcommand ~component_name ~subcommand_name ~setup_t =
    let doc =
      Fmt.str "Uninstall the parts of the component '%s' that need %s"
        component_name administrator
    in
    let cmd =
      ( setup_t,
        Term.info subcommand_name ~sdocs:Manpage.s_common_options ~doc )
    in
    Result.ok cmd

  let test () = ()
end
