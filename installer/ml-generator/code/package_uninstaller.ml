open Dkml_package_console_uninstaller
module Cmd = Cmdliner.Cmd
module Term = Cmdliner.Term

(* TEMPLATE: register () *)

let uninstall_cmd =
  let doc = "the uninstaller" in
  Cmd.v
    (Cmd.info "dkml-package-uninstaller" ~version:Private_common.program_version
       ~doc)
    Term.(
      const uninstall
      $ const (failwith "TEMPLATE: target_abi")
      $ const Private_common.program_name
      $ Dkml_package_console_common.package_args_t
          ~program_name:Private_common.program_name
          ~target_abi:(failwith "TEMPLATE: target_abi")
          ~install_direction:Dkml_install_register.Uninstall)

let () =
  Logs.set_reporter (Logs.format_reporter ());
  exit
    (Dkml_install_runner.Error_handling.catch_and_exit_on_error ~id:"68c85707"
       (fun () -> Cmd.eval ~catch:false uninstall_cmd))
