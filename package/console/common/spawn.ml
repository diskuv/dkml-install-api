open Bos
open Dkml_install_api

let spawn ?err_ok cmd =
  Logs.info (fun m -> m "Running: %a" Cmd.pp cmd);
  let fl = Dkml_install_runner.Error_handling.runner_fatal_log in
  let handle_err exitcode msg =
    match err_ok with
    | Some true ->
        Logs.warn (fun l -> l "A non-critical error occurred. %s" msg);
        Forward_progress.return ((), fl)
    | Some false | None ->
        fl ~id:"5f927a8b" msg;
        Forward_progress.(Halted_progress exitcode)
  in
  match OS.Cmd.(run_status cmd) with
  | Error e ->
      let msg =
        Fmt.str "@[Failed to run:@,@[%s@]@]@,@[%a@]" (Cmd.to_string cmd)
          Rresult.R.pp_msg e
      in
      handle_err Forward_progress.Exit_code.Exit_transient_failure msg
  | Ok (`Exited 0) -> Forward_progress.(return ((), fl))
  | Ok (`Exited spawned_exitcode) ->
      (* Use exit code of spawned process, but if and only if it matches
         one of the pre-defined exit codes. *)
      let exitcode =
        List.fold_left
          (fun acc ec ->
            if spawned_exitcode = Forward_progress.Exit_code.to_int_exitcode ec
            then ec
            else acc)
          Forward_progress.Exit_code.Exit_transient_failure
          Forward_progress.Exit_code.values
      in
      handle_err exitcode
        (Fmt.str
           "%s@.@.Root cause: @[<v 2>@[The command had exit code %d:@]@ \
            @[%a@]@]@.@.>>> %s <<<"
           (Forward_progress.Exit_code.to_short_sentence exitcode)
           spawned_exitcode Cmd.pp cmd
           (Forward_progress.Exit_code.to_short_sentence exitcode))
  | Ok (`Signaled v) ->
      handle_err Forward_progress.Exit_code.Exit_transient_failure
        (Fmt.str "Subprocess signaled with signal %d:@ %a" v Cmd.pp cmd)
