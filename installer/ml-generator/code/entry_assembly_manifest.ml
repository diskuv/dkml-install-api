let () =
  let version_m_n_o_p =
    Dkml_package_console_common.version_m_n_o_p Private_common.program_version
  in
  (* This generated manifest is merged with [entry-application.manifest] in `discover.ml` *)
  print_endline
    (Fmt.str
       {|<?xml version='1.0' encoding='UTF-8' standalone='yes'?>
<assembly xmlns='urn:schemas-microsoft-com:asm.v1' manifestVersion='1.0'>
  <assemblyIdentity type="win32" name="Diskuv.DkML.ConsoleEntrySetupExe" version="%s" />
</assembly>|}
       version_m_n_o_p)
