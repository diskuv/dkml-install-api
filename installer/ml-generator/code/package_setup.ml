open Dkml_package_console_setup
module Term = Cmdliner.Term

(* TEMPLATE: register () *)

let setup_cmd =
  let doc = "the DKML OCaml installer" in
  ( Term.(
      const setup
      $ const (failwith "TEMPLATE: target_abi")
      $ const Private_common.program_name
      $ Dkml_package_console_common.package_args_t
          ~program_name:Private_common.program_name
          ~target_abi:(failwith "TEMPLATE: target_abi")),
    Term.info "dkml-package-setup" ~version:"%%VERSION%%" ~doc )

let () =
  Term.(
    exit
    @@ Dkml_install_runner.Error_handling.catch_and_exit_on_error ~id:"bed30047"
         (fun () -> eval ~catch:false setup_cmd))
