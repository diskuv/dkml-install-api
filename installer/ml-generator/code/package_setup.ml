open Dkml_package_console_setup
module Cmd = Cmdliner.Cmd
module Term = Cmdliner.Term

(* TEMPLATE: register () *)

let setup_cmd =
  let doc = "the installer" in
  Cmd.v
    (Cmd.info "dkml-package-setup" ~version:Private_common.program_version ~doc)
    Term.(
      const setup
      $ const (failwith "TEMPLATE: target_abi")
      $ const Private_common.program_version
      $ const Private_common.organization
      $ const Private_common.program_name
      $ const Private_common.program_assets
      $ const Private_common.program_info
      $ Dkml_package_console_common.package_args_t
          ~program_name:Private_common.program_name
          ~target_abi:(failwith "TEMPLATE: target_abi")
          ~install_direction:Dkml_install_register.Install)

let () =
  Logs.set_reporter (Logs.format_reporter ());
  exit
    (Dkml_install_runner.Error_handling.catch_and_exit_on_error ~id:"bed30047"
       (fun () -> Cmd.eval ~catch:false setup_cmd))
