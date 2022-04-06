let generate ~archive_dir:_ ~target_dir:_ ~abi_selector ~installer_name
    ~installer_version =
  let abi_name =
    Dkml_install_runner.Path_location.show_abi_selector abi_selector
  in
  let installer_basename =
    Fmt.str "setup-%s-%s-%s.exe" installer_name abi_name installer_version
  in
  Logs.info (fun l -> l "Generating %s" installer_basename)
