let () =
  let version_m_n_o_p =
    Dkml_package_console_common.version_m_n_o_p Private_common.program_version
  in
  print_endline
    (Fmt.str
       "<?xml version='1.0' encoding='UTF-8' standalone='yes'?>\n\
        <assembly xmlns='urn:schemas-microsoft-com:asm.v1' \
        manifestVersion='1.0'>\n\
       \  <assemblyIdentity type=\"win32\" \
        name=\"Diskuv.DKML.ConsoleEntrySetupExe\" version=\"%s\" />\n\
        </assembly>"
       version_m_n_o_p)
