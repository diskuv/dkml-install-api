(* TEMPLATE: register () *)

let () =
  Dkml_install_runner_admin.main
    ~target_abi:(failwith "TEMPLATE: target_abi")
    ~package_name:Private_common.build_info.package_name
    ~program_version:Private_common.program_version
