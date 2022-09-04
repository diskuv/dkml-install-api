(* TEMPLATE: register () *)

let () =
  Dkml_install_runner_admin.main
    ~target_abi:(failwith "TEMPLATE: target_abi")
    ~program_version:Private_common.program_version
