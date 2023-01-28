(* TEMPLATE: register () *)

let () =
  exit
    (Dkml_package_console_create.create_installers Private_common.build_info
       Private_common.organization Private_common.program_name
       Private_common.program_info)
