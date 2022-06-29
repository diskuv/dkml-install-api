let runner_fatal_log ~id s =
  let open Dkml_install_api.Forward_progress in
  Logs.err (fun l ->
      let pp_style2 =
        if s = "" then Fmt.nop else Fmt.append Fmt.sp styled_fatal_message
      in
      l "%a%a@." styled_fatal_id id pp_style2 s)

let catch_and_exit_on_error ~id f =
  try f ()
  with e ->
    let msg = Printexc.to_string e and stack = Printexc.get_backtrace () in
    runner_fatal_log ~id
      (Fmt.str "@[%a@]@,@[%a@]" Fmt.lines msg Fmt.lines stack);
    exit
      (Dkml_install_api.Forward_progress.Exit_code.to_int_exitcode
         Exit_unrecoverable_failure)

let continue_or_exit = function
  | Dkml_install_api.Forward_progress.Completed ->
      raise (Invalid_argument "Unexpected 'Completed' forward progress")
  | Dkml_install_api.Forward_progress.Continue_progress (a, _fl) -> a
  | Dkml_install_api.Forward_progress.Halted_progress ec ->
      exit (Dkml_install_api.Forward_progress.Exit_code.to_int_exitcode ec)

let map_rresult_error_to_progress = function
  | Ok v ->
      Dkml_install_api.Forward_progress.Continue_progress (v, runner_fatal_log)
  | Error msg ->
      (* TODO: This [id] needs to be lifted into a parameter *)
      runner_fatal_log ~id:"72491215" (Fmt.str "%a" Rresult.R.pp_msg msg);
      Halted_progress Exit_transient_failure

let map_msg_error_to_progress = function
  | Ok v ->
      Dkml_install_api.Forward_progress.Continue_progress (v, runner_fatal_log)
  | Error (`Msg msg) ->
      (* TODO: This [id] needs to be lifted into a parameter *)
      runner_fatal_log ~id:"3f537898" msg;
      Halted_progress Exit_transient_failure

let map_string_error_to_progress = function
  | Ok v ->
      Dkml_install_api.Forward_progress.Continue_progress (v, runner_fatal_log)
  | Error msg ->
      (* TODO: This [id] needs to be lifted into a parameter *)
      runner_fatal_log ~id:"cd0f6a60" msg;
      Halted_progress Exit_transient_failure

(** Error monad with errors of type [string], for use in ppx_let. *)
module Let_syntax = struct
  module Let_syntax = struct
    let bind = Dkml_install_api.Forward_progress.bind

    let map = Dkml_install_api.Forward_progress.map

    let return v =
      Dkml_install_api.Forward_progress.Continue_progress (v, runner_fatal_log)
  end
end

module Monad_syntax = struct
  (* This is an error='polymorphic bind *)
  let ( >>= ) = Dkml_install_api.Forward_progress.bind

  (* This is an error='polymorphic map *)
  let ( >>| ) = Dkml_install_api.Forward_progress.map

  (* This is a error=string bind *)
  let ( let* ) = Let_syntax.Let_syntax.bind

  (* This is a error=string map *)
  let ( let+ ) x f = Let_syntax.Let_syntax.map f x

  let return = Let_syntax.Let_syntax.return
end
