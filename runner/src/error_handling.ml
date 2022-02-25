exception Installation_error of string

let () =
  Printexc.register_printer (function
    | Installation_error x -> Some ("Installation error: " ^ x)
    | _ -> None)

let errors_are_immediate () = true

let catch_cmdliner_eval f default_on_err =
  try f ()
  with e ->
    let msg = Printexc.to_string e and stack = Printexc.get_backtrace () in
    Logs.err (fun m -> m "@[%a@]@,@[%a@]" Fmt.lines msg Fmt.lines stack);
    default_on_err

(** Error monad with errors of type [string] *)
module Let_syntax = struct
  module Let_syntax = struct
    (** [bind r f] is the normal error monad or a monad that immediately throws
        a failure. *)
    let bind r f =
      match r with
      | Ok v -> f v
      | Error e ->
          if errors_are_immediate () then raise (Installation_error e)
          else Error e

    let map f = function
      | Ok v -> Ok (f v)
      | Error e ->
          if errors_are_immediate () then raise (Installation_error e)
          else Error e
  end
end
