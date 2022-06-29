(** {1 Introduction}

    [Forward_progress] provides common functions to handle graceful and
    informative exits from the nested chain of subprocesses typical in DKML
    Install API and many other applications.

    The module provides the {!return} and {!bind} monad which is similar to
    the error monad. This monad can be used to handle errors.

    When forward progress cannot be made, a process should:

    - log an informative error to the console or the appropriate log file
    - return a variant of {!Halted_progress}
    *)

(** A module for exit codes. *)
module Exit_code : sig
  (** The type of exit code.

    [Exit_unrecoverable_failure] is reserved for programmers error;
    basically assertions and unhandled exceptions that indicate
    the process cannot make forward progress, even if the process
    was restarted.

    [Exit_transient_failure] is for "normal" errors like I/O
    errors (not enough disk space, etc.), network errors, and
    the other errors that arise from Stdlib or 3rd party libraries
    giving a {!Result.t} or something similar.

    [Exit_restart_needed] is reserved for when a
    process requires itself to restart to make any forward
    progress. Typical use cases include re-initializing the
    process with updated configuration files.

    [Exit_reboot_needed] is reserved for when a
    process requires the machine to reboot to make any forward
    progress. Typical use cases include installations of system
    or widely-used shared libraries. You probably won't use it
    unless you write installers.

    [Exit_upgrade_required] is reserved for when a
    process or its dependencies (perhaps a kernel or system library)
    requires an upgrade to make any forward progress. Typical use cases
    include client software where old clients have been deprecated,
    and security-conscious software that requires patches to the machine
    before it will start up.
*)
  type t =
    | Exit_transient_failure
    | Exit_unrecoverable_failure
    | Exit_restart_needed
    | Exit_reboot_needed
    | Exit_upgrade_required

  val show : t -> string
  (** Pretty print as a string *)

  val pp : Format.formatter -> t -> unit
  (** Pretty print on the formatter *)

  val to_int_exitcode : t -> int
  (** An exitcode that can be supplied to {!exit} *)

  val to_short_sentence : t -> string
  (** A short sentence like "A transient failure occurred." *)
end

type fatal_logger = id:string -> string -> unit
(** The type of error logger.

    All errors include an error identifier which is
    conventionally
    the first 8 characters of a lowercase UUID
    (ex. ["de618005"]). *)

(** The type of forward progress *)
type 'a t =
  | Continue_progress of 'a * fatal_logger
  | Halted_progress of Exit_code.t
  | Completed

val return : 'a * fatal_logger -> 'a t
(** [return (a,fl)] wraps a fatal logger [fl] into the
    forward progress monad.

    It is simply [Continue_progress (a, fl)]. *)

val stderr : unit -> unit t
(** [stderr ()] wraps the standard error into the forward progress monad.

    It is simply
    [[
        Continue_progress ((), fun ~id s -> prerr_endline (id ^ ": " ^ s))
    ]] or something similar.

    The standard error output may include a timestamp, be word-wrapped,
    be colorized, etc. for friendliness to the end-user. *)

val stderr_fatallog : fatal_logger
(** [stderr_fatallog] is a fatal logger that prints to the standard error.

    [stderr_fatallog] is the same fatal logger used in {!stderr}.

    The standard error output may include a timestamp, be word-wrapped,
    be colorized, etc. for friendliness to the end-user. *)

val styled_fatal_id : string Fmt.t
(** Pretty-printer of an {!fatal_logger} [id]. Has color and styles.

    Example: [[
        # Prints something like the following in color:
        #   FATAL [724a6562].
        # without any newline.
        Fmt.epr "%a" styled_fatal_id "724a6562"
    ]] *)

val styled_fatal_message : string Fmt.t
(** Pretty-printer of an {!fatal_logger} error message. Has color and styles.

    Example: [[
        # Prints something like the following in color:
        #   I like blue
        # including a newline.
        Fmt.epr "%a" styled_fatal_message "I like blue"
    ]] *)

val catch_exceptions :
  id:string -> fatal_logger -> (fatal_logger -> 'a t) -> 'a t
(** [catch_exceptions ~id fl f] takes the fatal logger [fl] and executes [f fl],
    and any uncaught exceptions thrown during [f fl] will print a stack
    trace to [fatal_logger ~id] and return [Halted_progress Exit_unrecoverable_failure].

    In all other cases this function will return the value from [f fl]. *)

val bind : 'a t -> ('a * fatal_logger -> 'b t) -> 'b t
(** [bind fwd f] is the bind monad function that, if [fwd = Continue_progress (u, fatal_logger)],
    will return [f (u, fatal_logger)].

    The bind monad behaves similarly to the error monad.

    It is the responsibility of the developer to log an informative error to the
    [fatal_logger] before returning [Halted_progress exitcode].
    *)

val map : ('a -> 'b) -> 'a t -> 'b t
(** [map f fwd] is the map monad function that, if [fwd = Continue_progress (u, fatal_logger)],
    will return [Continue_progress (f u, fatal_logger)] *)

val lift_result :
  string * int * int * int ->
  (Format.formatter -> 'e -> unit) ->
  fatal_logger ->
  ('a, 'e) result ->
  'a t
(** [lift_result pos efmt fl res] lifts the [res] result with string errors
    into the forward progress monad.

    Any error is immediately printed to the error logger using the supplied
    error format [efmt] and converted to an {!Exit_transient_failure}.

    For a [res] result with string errors, example error formats are:
    [[
        let efmt fmt = Fmt.pf fmt "FATAL: %s"
    ]]
    and
    [[
        let efmt fmt = Format.fprintf fmt
            "@[Bad failure!@]@,@[%a@]@." Fmt.lines
    ]]

    The error is identified by [pos] which is typically set to [__POS__].
    See {!pos_to_id} and {!__POS__}. *)

val pos_to_id : string * int * int * int -> string
(** [pos_to_id (file,lnum,cnum,enum)] converts a compiled location
    [(file,lnum,cnum,enum)] into an 8 digit lowercase hex identifier.

    Only the basename of the source code [file] and the line number
    [lnum] participate in the identification. *)

val iter : fl:fatal_logger -> ('a -> unit t) -> 'a list -> unit t
(** [iter ~fl f lst] iterates over the items of the list [lst] with the function [f].
    If any [lst] item gives back anything but {!Continue_progress} then the
    iteration will stop. *)
