(* TEMPLATE: register () *)

let () =
  let program_version =
    match Build_info.V1.version () with
    | None -> "dev"
    | Some v -> Build_info.V1.Version.to_string v
  in
  Dkml_install_runner_admin.main
    ~target_abi:(failwith "TEMPLATE: target_abi")
    ~program_version
