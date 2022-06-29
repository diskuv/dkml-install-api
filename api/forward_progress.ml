module Exit_code = struct
  type t =
    | Exit_transient_failure
    | Exit_unrecoverable_failure
    | Exit_restart_needed
    | Exit_reboot_needed
    | Exit_upgrade_required

  let show = function
    | Exit_transient_failure -> "Exit_transient_failure"
    | Exit_unrecoverable_failure -> "Exit_unrecoverable_failure"
    | Exit_restart_needed -> "Exit_restart_needed"
    | Exit_reboot_needed -> "Exit_reboot_needed"
    | Exit_upgrade_required -> "Exit_upgrade_required"

  let pp fmt v = Fmt.pf fmt "%s" (show v)

  let to_int_exitcode = function
    | Exit_transient_failure -> 20
    | Exit_unrecoverable_failure -> 21
    | Exit_restart_needed -> 22
    | Exit_reboot_needed -> 23
    | Exit_upgrade_required -> 24

  let to_short_sentence = function
    | Exit_transient_failure -> "A transient failure occurred."
    | Exit_unrecoverable_failure -> "An unrecoverable failure occurred."
    | Exit_restart_needed -> "The process needs to be restarted."
    | Exit_reboot_needed -> "The machine needs rebooting."
    | Exit_upgrade_required -> "An upgrade needs to happen."
end

type fatal_logger = id:string -> string -> unit

type 'a t =
  | Continue_progress of 'a * fatal_logger
  | Halted_progress of Exit_code.t
  | Completed

let return (a, fl) = Continue_progress (a, fl)

let styled_fatal_id =
  let pp1 = Fmt.styled (`Fg `Red) (fun fmt -> Fmt.pf fmt "FATAL [%s].") in
  Fmt.styled `Bold pp1

let styled_fatal_message =
  Fmt.styled (`Fg `Red) (fun fmt -> Fmt.pf fmt "%a@." Fmt.lines)

let stderr_fatallog ~id s =
  if s = "" then Fmt.epr "%a@." styled_fatal_id id
  else Fmt.epr "%a %a@." styled_fatal_id id styled_fatal_message s

let stderr () = Continue_progress ((), stderr_fatallog)

let bind fwd f =
  match fwd with
  | Continue_progress (u, fl) -> f (u, fl)
  | Halted_progress exitcode -> Halted_progress exitcode
  | Completed -> Completed

let map f fwd =
  match fwd with
  | Continue_progress (u, fl) -> Continue_progress (f u, fl)
  | Halted_progress exitcode -> Halted_progress exitcode
  | Completed -> Completed

let catch_exceptions ~id fl f =
  try f fl
  with _ ->
    fl ~id (Printexc.get_backtrace ());
    Halted_progress Exit_unrecoverable_failure

let pos_to_id (file, lnum, _cnum, _enum) =
  let basename = Filename.basename file in
  (* The order matters for the pre-hash. Put parts
     of the identification that will not have a separator (comma)
     before the filename which could conceivably include
     a separator. *)
  let prehash = Fmt.str "%d,%s" lnum basename in
  (* Digest is MD5 hash *)
  let hash = Digest.(string prehash |> to_hex |> String.lowercase_ascii) in
  String.sub hash 0 8

let lift_result pos efmt fl = function
  | Ok v -> return (v, fl)
  | Error e ->
      fl ~id:(pos_to_id pos) (Fmt.str "%a" efmt e);
      Halted_progress Exit_transient_failure

let iter ~fl f =
  List.fold_left
    (fun acc v ->
      match acc with
      | Continue_progress ((), _fl) -> f v
      | Halted_progress u -> Halted_progress u
      | Completed -> Completed)
    (Continue_progress ((), fl))
