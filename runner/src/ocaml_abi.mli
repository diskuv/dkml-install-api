(** The OCaml ABI that comes from intropecting the OCaml bytecode interpreter.

    Consider {!Host_abi} instead of the OCaml ABI if you are inspecting the
    end-user's machine. *)

val create_v2 : unit -> (Dkml_install_api.Context.Abi_v2.t, string) result
(** [create_v2 ()] will detect the OCaml ABI from the list of V2 ABIs. Any
    OCaml ABIs added after V2 will give a [Result.Error]. *)
