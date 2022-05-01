(** The host ABI.

    Use when you cannot rely on inspecting the
    OCaml bytecode interpreter since the
    interpreter is often compiled to 32-bit for maximum portability. *)

val create_v2 : unit -> (Dkml_install_api.Context.Abi_v2.t, string) result
(** [create_v2 ()] will detect the host ABI from the list of V2 ABIs. Any
    host ABIs added after V2 will give a [Result.Error]. *)
