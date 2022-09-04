open Dkml_package_console_setup
module Term = Cmdliner.Term

(* TEMPLATE: register () *)

let setup_cmd =
  let doc = "the DKML OCaml installer" in
  ( Term.(
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
          ~install_direction:
            Dkml_install_runner.Path_eval.Global_context.Install),
    Term.info "dkml-package-setup" ~version:Private_common.program_version ~doc
  )

let () =
  Term.(
    exit
    @@ Dkml_install_runner.Error_handling.catch_and_exit_on_error ~id:"bed30047"
         (fun () -> eval ~catch:false setup_cmd))
