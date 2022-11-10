(* Cmdliner 1.0 -> 1.1 deprecated a lot of things. But until Cmdliner 1.1
   is in common use in Opam packages we should provide backwards compatibility.
   In fact, Diskuv OCaml is not even using Cmdliner 1.1. *)
[@@@alert "-deprecated"]

(* TEMPLATE: register () *)

let () =
  Cmdliner.Term.(
    exit
    @@ Dkml_package_console_create.create_installers Private_common.organization
         Private_common.program_name Private_common.program_info)
