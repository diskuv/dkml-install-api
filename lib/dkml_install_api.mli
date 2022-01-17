module type Plugin_config = Types.Plugin_config

(** The module [Private] is meant for internal use only. *)
module Private : sig
    val validate : (module Types.Plugin_config) -> (unit, string) result
end