let () =
  Dkml_package_console_entry.entry ~install_direction:Uninstall
    ~target_abi:(failwith "TEMPLATE: target_abi")
