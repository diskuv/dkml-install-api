module Arg = Cmdliner.Arg
module Term = Cmdliner.Term
module Cmd = Cmdliner.Cmd
module Context = Types.Context
module Forward_progress = Forward_progress

module type Component_config = Dkml_install_api_intf.Component_config

module type Component_config_defaultable =
  Dkml_install_api_intf.Component_config_defaultable

let administrator =
  if Sys.win32 then "Administrator privileges" else "root permissions"

module Default_component_config = struct
  let install_depends_on = []
  let uninstall_depends_on = []
  let do_nothing_with_ctx_t _ctx = ()
  let sdocs = Cmdliner.Manpage.s_common_options

  let install_user_subcommand ~component_name ~subcommand_name ~fl ~ctx_t =
    let doc =
      Fmt.str
        "Currently does nothing. Would install the component '%s' except the \
         parts, if any, that need %s"
        component_name administrator
    in
    let info = Cmd.info subcommand_name ~sdocs ~doc in
    let cmd = Cmd.v info Term.(const do_nothing_with_ctx_t $ ctx_t) in
    Forward_progress.return (cmd, fl)

  let uninstall_user_subcommand ~component_name ~subcommand_name ~fl ~ctx_t =
    let doc =
      Fmt.str
        "Currently does nothing. Would uninstall the component '%s' except the \
         parts, if any, that need %s"
        component_name administrator
    in
    let info = Cmd.info subcommand_name ~sdocs ~doc in
    let cmd = Cmd.v info Term.(const do_nothing_with_ctx_t $ ctx_t) in
    Forward_progress.return (cmd, fl)

  let needs_install_admin ~ctx:(_ : Context.t) = false
  let needs_uninstall_admin ~ctx:(_ : Context.t) = false

  let install_admin_subcommand ~component_name ~subcommand_name ~fl ~ctx_t =
    let doc =
      Fmt.str
        "Currently does nothing. Would install the parts of the component '%s' \
         that need %s"
        component_name administrator
    in
    let info = Cmd.info subcommand_name ~sdocs ~doc in
    let cmd = Cmd.v info Term.(const do_nothing_with_ctx_t $ ctx_t) in
    Forward_progress.return (cmd, fl)

  let uninstall_admin_subcommand ~component_name ~subcommand_name ~fl ~ctx_t =
    let doc =
      Fmt.str
        "Currently does nothing. Would uninstall the parts of the component \
         '%s' that need %s"
        component_name administrator
    in
    let info = Cmd.info subcommand_name ~sdocs ~doc in
    let cmd = Cmd.v info Term.(const do_nothing_with_ctx_t $ ctx_t) in
    Forward_progress.return (cmd, fl)

  let test () = ()
end

module Log_config = struct
  include Log_config
end

let log_spawn_onerror_exit ~id ?(success_exitcodes = fun i -> i == 0)
    ?conformant_subprocess_exitcodes cmd =
  Logs.info (fun m -> m "Running command: %a" Bos.Cmd.pp cmd);
  let fl = Forward_progress.stderr_fatallog in
  let open Astring in
  let sequence =
    let ( let* ) = Result.bind in
    let* env = Bos.OS.Env.current () in
    let new_env =
      let is_not_defined =
        match String.Map.find "OCAMLRUNPARAM" env with
        | None -> true
        | Some "" -> true
        | Some _ -> false
      in
      if is_not_defined then String.Map.add "OCAMLRUNPARAM" "b" env else env
    in
    Bos.OS.Cmd.run_status ~env:new_env cmd
  in
  match sequence with
  | Ok (`Exited spawned_exitcode) when success_exitcodes spawned_exitcode ->
      if Logs.level () = Some Logs.Debug then
        Logs.info (fun m ->
            m "%a ran successfully with exit code %d" Bos.Cmd.pp cmd
              spawned_exitcode)
      else
        Logs.info (fun m ->
            m "%a ran successfully with exit code %d"
              Fmt.(option string)
              (Bos.Cmd.line_tool cmd) spawned_exitcode);
      ()
  | Ok (`Exited spawned_exitcode) ->
      let adjective, exitcode =
        if conformant_subprocess_exitcodes = Some false then
          ("", Forward_progress.Exit_code.Exit_transient_failure)
        else
          ( "conformant ",
            List.fold_left
              (fun acc ec ->
                if
                  spawned_exitcode
                  = Forward_progress.Exit_code.to_int_exitcode ec
                then ec
                else acc)
              Forward_progress.Exit_code.Exit_transient_failure
              Forward_progress.Exit_code.values )
      in
      fl ~id
        (Fmt.str
           "%s\n\n\
            Root cause: @[The %scommand had exit code %d:@ %a@]\n\n\
            >>> %s <<<"
           (Forward_progress.Exit_code.to_short_sentence exitcode)
           adjective spawned_exitcode Bos.Cmd.pp cmd
           (Forward_progress.Exit_code.to_short_sentence exitcode));
      exit (Forward_progress.Exit_code.to_int_exitcode exitcode)
  | Ok (`Signaled c) ->
      fl ~id
        (Fmt.str "The command@ %a@ terminated from a signal %d" Bos.Cmd.pp cmd c);
      exit (Forward_progress.Exit_code.to_int_exitcode Exit_transient_failure)
  | Error rmsg ->
      fl ~id
        (Fmt.str "The command@ %a@ could not be run due to: %a" Bos.Cmd.pp cmd
           Rresult.R.pp_msg rmsg);
      exit (Forward_progress.Exit_code.to_int_exitcode Exit_transient_failure)

module Immediate_fail (Id : sig
  val id : string
end) =
struct
  let ( let* ) r f =
    match r with
    | Ok v -> f v
    | Error s ->
        Forward_progress.stderr_fatallog ~id:Id.id
          (Fmt.str "%a" Rresult.R.pp_msg s);
        exit (Forward_progress.Exit_code.to_int_exitcode Exit_transient_failure)

  let ( let+ ) f x = Rresult.R.map x f
end

let chmod_plus_readwrite_path ~id path =
  let open Immediate_fail (struct
    let id = id
  end) in
  let* mode = Bos.OS.Path.Mode.get path in
  if mode land 0o600 <> 0o600 then
    let+ () = Bos.OS.Path.Mode.set path (mode lor 0o600) in
    ()
  else Ok ()

let chmod_plus_readwrite_dir ~id dir =
  let open Immediate_fail (struct
    let id = id
  end) in
  let raise_fold_error fpath result =
    Rresult.R.error_msgf
      "@[A chmod u+rw directory operation errored out while visiting %a.@]@,\
       @[  @[%a@]@]" Fpath.pp fpath
      (Rresult.R.pp
         ~ok:(Fmt.any "<unknown rmdir problem>")
         ~error:Rresult.R.pp_msg)
      result
  in
  let f rel = function
    | Error _ as e ->
        (* no more chmod if we had an error *)
        e
    | Ok () -> chmod_plus_readwrite_path ~id Fpath.(dir // rel)
  in
  let* res = Bos.OS.Path.fold ~err:raise_fold_error f (Ok ()) [ dir ] in
  match res with
  | Ok () -> Ok ()
  | Error s ->
      Rresult.R.error_msg
        (Fmt.str "@[@[Failed to chmod u+rw the directory@]@[@ %a@]@ .@]@ @[%a@]"
           Fpath.pp dir Rresult.R.pp_msg s)

(** [dos2unix s] converts all CRLF sequences in [s] into LF. Assumes [s] is ASCII encoded. *)
let dos2unix s =
  let l = String.length s in
  String.to_seqi s
  (* Shrink [\r\n] into [\n] *)
  |> Seq.filter_map (function
       | i, '\r' when i + 1 < l && s.[i + 1] == '\n' -> None
       | _, c -> Some c)
  |> String.of_seq

let styled_stuck_info fmt =
  let pp1 = Fmt.styled (`Fg `Magenta) fmt in
  let pp2 = Fmt.styled (`Bg `Black) pp1 in
  Fmt.styled `Bold pp2

let styled_stuck_detail fmt =
  let pp1 = Fmt.styled (`Fg `Red) fmt in
  let pp2 = Fmt.styled (`Bg `Black) pp1 in
  let pp3 = Fmt.styled `Bold pp2 in
  Fmt.styled `Underline pp3

let delete_path_on_windows ~id ~path ~wait_seconds_if_stuck ~comspec ~cmd
    ~options =
  let open Immediate_fail (struct
    let id = id
  end) in
  (*
          https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/rd

          Example:

            rd "C:\Temp\abc" /s /q
          
          And instead of dealing with insane OCaml + DOS quoting issues, will
          create a temporary batch file and execute that.

          Other complexity is we won't get any error codes from `rd`. But we will get:
            C:\Users\beckf\AppData\Local\Temp\f46f0508-df03-40e8-8661-728f1be41647\UninstallBlueGreenDeploy2\0\cmd.exe - Access is denied.
          So any output on the error console indicates a problem.
          *)
  let cmd =
    Printf.sprintf "@%s %s %s" cmd options
      (Filename.quote (Fpath.to_string path))
  in
  let* batchfile = Bos.OS.File.tmp "delpath_%s.bat" in
  let* () = Bos.OS.File.write batchfile cmd in
  let start_secs = Unix.time () in
  let rec helper () =
    match
      Bos.OS.Cmd.run_out ~err:Bos.OS.Cmd.err_run_out
        Bos.Cmd.(v comspec % "/c" % Fpath.to_string batchfile)
      |> Bos.OS.Cmd.out_string
    with
    | Ok ("", (_, `Exited 0)) -> Ok ()
    | Ok (text, (_, `Exited 0)) ->
        (* Exit 0 with any stdout/stderr is a problem. We used 'rd /q' or 'del /q'
           to suppress output, so any output is an error. *)
        let now_secs = Unix.time () in
        let elapsed_secs = now_secs -. start_secs in
        if elapsed_secs > wait_seconds_if_stuck then
          Error
            (Rresult.R.msgf "The DOS command '%s' did not succeed.@,@[<v>%a@]"
               cmd Fmt.lines (dos2unix text))
        else (
          (* Retry until time complete *)
          Fmt.epr
            "@[<v>@,\
             Stuck during uninstallation of %a@,\
             Waited already %5.1f seconds; will wait at most %5.1f seconds.@,\
             %a@,\
             @[  %a@]@]@,\
             @."
            Fpath.pp path elapsed_secs wait_seconds_if_stuck
            (styled_stuck_info Fmt.string)
            "Please stop and exit the program:"
            (styled_stuck_detail Fmt.lines)
            (dos2unix text);
          Unix.sleep 5;
          helper ())
    | Ok (text, (_, `Exited v)) ->
        Error
          (Rresult.R.msgf
             "The DOS command DOS '%s' exited with exit code %d.@,@[<v>%a@]" cmd
             v Fmt.lines (dos2unix text))
    | Ok (text, (_, `Signaled v)) ->
        Error
          (Rresult.R.msgf
             "The DOS command DOS '%s' was killed by signal %d.@,@[<v>%a@]" cmd
             v Fmt.lines (dos2unix text))
    | Error msg -> Error msg
  in
  helper ()
(*
                     let helper () =
                       match
                         Bos.OS.Cmd.run_out Bos.Cmd.(v comspec % "/c" % cmd)
                         |> Bos.OS.Cmd.out_string
                       with
                       | Ok ("", (_, `Exited 0)) -> Ok ()
                       | Ok (text, (_, `Exited 0)) ->
                           Error
                             (Rresult.R.msgf
                                "DOS 'rd' exited with exit code 0, but should not have \
                                 produced output.@,\
                                 @[<v>%a@]"
                                Fmt.lines (dos2unix text))
                       | Ok (text, (_, `Exited v)) ->
                           Error
                             (Rresult.R.msgf
                                "DOS 'rd' exited with exit code %d.@,@[<v>%a@]" v Fmt.lines
                                (dos2unix text))
                       | Ok (text, (_, `Signaled v)) ->
                           Error
                             (Rresult.R.msgf "DOS 'rd' killed by signal %d.@,@[<v>%a@]" v
                                Fmt.lines (dos2unix text))
                       | Error msg -> Error msg
                     in
                     helper () 
                     
                     *)
(* let ic =
     Unix.open_process_args_in comspec
       [| "/s"; "/c"; cmd  |]
   in
   let rd_output = really_input_string ic 0 |> dos2unix in
   match Unix.close_process_in ic with
   | WEXITED 0 when rd_output = "" -> Ok ()
   | WEXITED 0 ->
       Error
         (Rresult.R.msgf
            "DOS 'rd' exited with exit code 0, but should not have \
             produced output.@,\
             @[<v>%a@]"
            Fmt.lines rd_output)
   | WEXITED v ->
       Error
         (Rresult.R.msgf "DOS 'rd' exited with exit code %d.@,@[<v>%a@]"
            v Fmt.lines rd_output)
   | WSIGNALED v ->
       Error
         (Rresult.R.msgf "DOS 'rd' killed by signal %d.@,@[<v>%a@]" v
            Fmt.lines rd_output)
   | WSTOPPED v ->
       Error
         (Rresult.R.msgf "DOS 'rd' stopped by signal %d.@,@[<v>%a@]" v
            Fmt.lines rd_output))
*)

(*
                    (match Unix.system cmd with
                    | WEXITED 0 -> Ok ()
                    | WEXITED v ->
                        Error (Rresult.R.msgf "DOS 'rd' exited with exit code %d" v)
                    | WSIGNALED v ->
                        Error (Rresult.R.msgf "DOS 'rd' killed by signal %d" v)
                    | WSTOPPED v ->
                        Error (Rresult.R.msgf "DOS 'rd' stopped by signal %d" v))
      *)

let uninstall_directory_onerror_exit ~id ~dir ~wait_seconds_if_stuck =
  let open Immediate_fail (struct
    let id = id
  end) in
  (* On Windows we need to get write access before you can delete the
      file. *)
  let fl = Forward_progress.stderr_fatallog in
  let sequence =
    let* exists = Bos.OS.Path.exists dir in
    if exists then (
      Logs.info (fun m -> m "Uninstalling directory: %a" Fpath.pp dir);
      let* () = chmod_plus_readwrite_dir ~id dir in
      (*
         OS.Dir.delete has bizarre error messages, like:

           C:\Users\beckf\AppData\Local\Temp\build999583.dune\test_uninstall_7b4501\cmd.exe: The directory name is invalid.

         when the above cmd.exe is being used. So we use cmd.exe on Windows instead which
         has user-friendly DOS error messages.
      *)
      match (Sys.win32, Bos.OS.Env.var "COMSPEC") with
      | true, Some comspec when comspec != "" ->
          (*
          https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/rd

          Example:

            rd "C:\Temp\abc" /s /q
          
          And instead of dealing with insane OCaml + DOS quoting issues, will
          create a temporary batch file and execute that.

          Other complexity is we won't get any error codes from `rd`. But we will get:
            C:\Users\beckf\AppData\Local\Temp\f46f0508-df03-40e8-8661-728f1be41647\UninstallBlueGreenDeploy2\0\cmd.exe - Access is denied.
          So any output on the error console indicates a problem.
          *)
          delete_path_on_windows ~id ~path:dir ~wait_seconds_if_stuck ~comspec
            ~cmd:"rd" ~options:"/s /q"
      | _ -> Bos.OS.Dir.delete ~recurse:true dir)
    else Ok ()
  in
  match sequence with
  | Ok () -> ()
  | Error rmsg ->
      fl ~id
        (Fmt.str "The directory@ %a@ could not be uninstalled due to: %a"
           Fpath.pp dir Rresult.R.pp_msg rmsg);
      exit (Forward_progress.Exit_code.to_int_exitcode Exit_transient_failure)

let uninstall_file_onerror_exit ~id ~file ~wait_seconds_if_stuck =
  let open Immediate_fail (struct
    let id = id
  end) in
  (* On Windows we need to get write access before you can delete the file. *)
  let fl = Forward_progress.stderr_fatallog in
  let sequence =
    let* exists = Bos.OS.Path.exists file in
    if exists then (
      Logs.info (fun m -> m "Uninstalling file: %a" Fpath.pp file);
      let* () = chmod_plus_readwrite_path ~id file in
      (*
               OS.Dir.delete has bizarre error messages, like:
      
                 C:\Users\beckf\AppData\Local\Temp\build999583.dune\test_uninstall_7b4501\cmd.exe: The directory name is invalid.
      
               when the above cmd.exe is being used. So we use cmd.exe on Windows instead which
               has user-friendly DOS error messages.
            *)
      match (Sys.win32, Bos.OS.Env.var "COMSPEC") with
      | true, Some comspec when comspec != "" ->
          (*
                https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/del
      
                Example:
      
                  del "C:\Temp\abc" /f /q
                
                And instead of dealing with insane OCaml + DOS quoting issues, will
                create a temporary batch file and execute that.
      
                Other complexity is we won't get any error codes from `del`. But we will get:
                  Y:\temp\ocamllsp.exe
                  Access is denied.
                So any output on the error console indicates a problem.
                *)
          delete_path_on_windows ~id ~path:file ~wait_seconds_if_stuck ~comspec
            ~cmd:"del" ~options:"/f /q"
      | _ -> Bos.OS.File.delete file)
    else Ok ()
  in
  match sequence with
  | Ok () -> ()
  | Error rmsg ->
      fl ~id
        (Fmt.str "The file@ %a@ could not be uninstalled due to: %a" Fpath.pp
           file Rresult.R.pp_msg rmsg);
      exit (Forward_progress.Exit_code.to_int_exitcode Exit_transient_failure)
