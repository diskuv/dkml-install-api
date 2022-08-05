(* open More_testables *)

let id = "859c20bc"

let test_empty_directory () =
  let dir = Result.get_ok @@ Bos.OS.Dir.tmp "test_uninstall1_%s" in
  Dkml_install_api.uninstall_directory_onerror_exit ~id ~dir
    ~wait_seconds_if_stuck:5.0

let test_directory_with_running_process () =
  let dir = Result.get_ok @@ Bos.OS.Dir.tmp "test_uninstall2_%s" in
  match (Sys.win32, Bos.OS.Env.var "COMSPEC") with
  | true, Some comspec when comspec != "" ->
      (* We'll copy cmd.exe (something present on all Windows machines, including
         CI) to mimic a real deployment that could contain ocamlrun.exe,
         ocamllsp.exe, dune.exe, etc. (any process that could be running during
         an uninstall). *)
      let deployed_program = Fpath.(dir / "cmd.exe") in
      Result.get_ok
      @@ Diskuvbox.copy_file ~src:(Fpath.v comspec) ~dst:deployed_program ();
      (* Use our deployed cmd.exe to run for 15 seconds. Ideally we would use
         'timeout' but that will not work in a CI scenario where there is no
         standard input. Instead we use ping. Inspired by
         https://stackoverflow.com/questions/1672338/how-to-sleep-for-five-seconds-in-a-batch-file-cmd *)
      let (_pid : int) =
        Unix.create_process
          (Fpath.to_string deployed_program)
          [| "/c"; "ping 127.0.0.1 -n 15" |]
          Unix.stdin Unix.stdout Unix.stderr
      in
      let start_secs = Unix.time () in
      (* Wait one second to make sure our background ping is running *)
      Unix.sleep 1;
      (* Do uninstall, which should block for 15 seconds *)
      Dkml_install_api.uninstall_directory_onerror_exit ~id ~dir
        ~wait_seconds_if_stuck:15.0;
      let finish_secs = Unix.time () in
      let elapsed_secs = finish_secs -. start_secs in
      if elapsed_secs < 5.0 then
        Alcotest.fail
          (Printf.sprintf
             "Expected uninstall would block for about 15 seconds. It only \
              blocked for %f seconds"
             elapsed_secs)
  | _ -> ()

let () =
  let open Alcotest in
  run "Uninstall"
    [
      ( "directory",
        [
          test_case "Empty" `Quick test_empty_directory;
          test_case "Running process" `Slow test_directory_with_running_process;
        ] );
    ]
