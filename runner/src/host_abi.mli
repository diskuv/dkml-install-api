(** The host ABI.

    Use when you cannot rely on inspecting the
    OCaml bytecode interpreter since the
    interpreter is often compiled to 32-bit for maximum portability. *)

val create_v2 :
  unit -> Dkml_install_api.Context.Abi_v2.t Dkml_install_api.Forward_progress.t
(** [create_v2 ()] will detect the host ABI from the list of V2 ABIs. Any
    host ABIs added after V2 will return
    [Dkml_install_api.Forward_progress.Halted_progress Dkml_install_api.Forward_progress.Exit_code.Exit_unrecoverable_failure]. *)
