(* Cmdliner 1.0 -> 1.1 deprecated a lot of things. But until Cmdliner 1.1
   is in common use in Opam packages we should provide backwards compatibility.
   In fact, Diskuv OCaml is not even using Cmdliner 1.1. *)
[@@@alert "-deprecated"]

open Dkml_package_console_uninstaller
module Term = Cmdliner.Term

(* TEMPLATE: register () *)

let uninstall_cmd =
  let doc = "the uninstaller" in
  ( Term.(
      const uninstall
      $ const (failwith "TEMPLATE: target_abi")
      $ const Private_common.program_name
      $ Dkml_package_console_common.package_args_t
          ~program_name:Private_common.program_name
          ~target_abi:(failwith "TEMPLATE: target_abi")
          ~install_direction:
            Dkml_install_runner.Path_eval.Global_context.Uninstall),
    Term.info "dkml-package-uninstaller" ~version:Private_common.program_version
      ~doc )

let () =
  Term.(
    exit
    @@ Dkml_install_runner.Error_handling.catch_and_exit_on_error ~id:"68c85707"
         (fun () -> eval ~catch:false uninstall_cmd))
