let () =
  Printexc.register_printer (function
    | Dkml_install_api.Installation_error x -> Some ("Installation error: " ^ x)
    | _ -> None)

let errors_are_immediate () = true

let get_ok_or_raise_string = function
  | Ok v -> v
  | Error msg -> raise (Dkml_install_api.Installation_error msg)

let catch_cmdliner_eval f default_on_err =
  try f ()
  with e ->
    let msg = Printexc.to_string e and stack = Printexc.get_backtrace () in
    Logs.err (fun m -> m "@[%a@]@,@[%a@]" Fmt.lines msg Fmt.lines stack);
    default_on_err

let map_rresult_error_to_string = function
  | Ok v -> Result.ok v
  | Error msg -> Result.error (Fmt.str "%a" Rresult.R.pp_msg msg)

let map_msg_error_to_string = function
  | Ok v -> Result.ok v
  | Error (`Msg msg) -> Result.error msg

(** Error monad with errors of type [string], for use in ppx_let. *)
module Let_syntax = struct
  module Let_syntax = struct
    (** [bind r f] is the normal error monad or a monad that immediately throws
        a failure. *)
    let bind r f =
      match r with
      | Ok v -> f v
      | Error e ->
          if errors_are_immediate () then
            raise (Dkml_install_api.Installation_error e)
          else Error e

    let map f = function
      | Ok v -> Ok (f v)
      | Error e ->
          if errors_are_immediate () then
            raise (Dkml_install_api.Installation_error e)
          else Error e
  end
end

module Monad_syntax = struct
  (* This is an error='polymorphic bind *)
  let ( >>= ) = Result.bind

  (* This is an error='polymorphic map *)
  let ( >>| ) = Result.map

  (* This is a error=string bind *)
  let ( let* ) = Let_syntax.Let_syntax.bind

  (* This is a error=string map *)
  let ( let+ ) x f = Let_syntax.Let_syntax.map f x
end
