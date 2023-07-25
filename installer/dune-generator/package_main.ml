open Sexplib0
module Arg = Cmdliner.Arg
module Cmd = Cmdliner.Cmd
module Term = Cmdliner.Term

(* {1 Directories} *)

let fpath_pp_mixed fmt v =
  let s = Fmt.str "%a" Fpath.pp v in
  Fmt.pf fmt "%s" (String.map (function '\\' -> '/' | c -> c) s)

let pwd () = Rresult.R.error_msg_to_invalid_arg (Bos.OS.Dir.current ())

let project_abs_dir ~pwd project_root =
  if Fpath.is_rel project_root then Fpath.(pwd // project_root)
  else project_root

let project_rel_dir project_root =
  let pwd = pwd () in
  let project_root = Fpath.v project_root in
  match Fpath.relativize ~root:(project_abs_dir ~pwd project_root) pwd with
  | Some v -> v
  | None ->
      failwith
        (Fmt.str "Could not get relative directory of %a in %a" Fpath.pp
           project_root Fpath.pp pwd)

let write_dune_inc fmt ~output_rel dune_inc =
  let output_reldir = Fpath.parent output_rel in
  Fmt.pf fmt "; Auto-generated by package-dune-of-installer-generator.exe.@\n";
  Fmt.pf fmt "; Do not edit unless need to regenerate!@\n";
  Fmt.pf fmt
    "; When regenerating, erase **all** content from this file, save the file, \
     and then run:@\n";
  Fmt.pf fmt ";   dune clean@\n";
  Fmt.pf fmt ";   dune build '@%a/gen-dkml' --auto-promote@\n" fpath_pp_mixed
    output_reldir;
  Fmt.pf fmt "%a@\n" Fmt.(list ~sep:(any "@\n@\n") Sexp.pp_hum) dune_inc;
  Format.pp_print_flush fmt ()

let main () project_root package_name common_dir corrected =
  let components = Common_installer_generator.ocamlfind () in
  let dkml_components = List.map (fun s -> "dkml-component-" ^ s) components in
  let project_rel_dir = project_rel_dir project_root in
  let common_dir_slash =
    Fpath.(v common_dir |> normalize |> to_string)
    |> String.map (function '\\' -> '/' | c -> c)
  in
  let with_common_dir f = common_dir_slash ^ f in
  let loglevel_flags =
    (* See how link.exe is invoked through flexlink.exe *)
    match Logs.level () with
    | Some Logs.Debug | Some Logs.Info -> [ Sexp.Atom "-cclib"; Atom "-v" ]
    | _ -> []
  in
  let dune_inc =
    Dune_sexp.
      [
        executable
          [
            public_name (package_name ^ "-user-runner");
            package package_name;
            name "runner_user";
            modules [ "runner_user" ];
            ocamlopt_flags
              [
                List
                  (loglevel_flags
                  @ [
                      Atom ":include";
                      Atom (with_common_dir "user-link-flags.sexp");
                    ]);
              ];
            libraries
              ([ "dkml-install-runner.user"; "private_common" ]
              @ dkml_components);
          ];
        executable
          [
            public_name (package_name ^ "-admin-runner");
            package package_name;
            name "runner_admin";
            modules [ "runner_admin" ];
            ocamlopt_flags
              [
                List
                  (loglevel_flags
                  @ [
                      Atom ":include";
                      Atom (with_common_dir "admin-link-flags.sexp");
                    ]);
              ];
            libraries
              ([ "dkml-install-runner.admin"; "private_common" ]
              @ dkml_components);
          ];
        executable
          [
            public_name (package_name ^ "-create-installers");
            package package_name;
            name "create_installers";
            libraries
              ([ "dkml-package-console.create"; "cmdliner"; "private_common" ]
              @ dkml_components);
            modules [ "create_installers" ];
          ];
        executable
          [
            public_name (package_name ^ "-package-install");
            package package_name;
            name "entry_install";
            libraries
              ([ "dkml-package-console.entry"; "cmdliner"; "private_common" ]
              @ dkml_components);
            modules [ "entry_install" ];
            ocamlopt_flags
              [
                List
                  (loglevel_flags
                  @ [
                      Atom ":include";
                      Atom (with_common_dir "console-link-flags.sexp");
                    ]);
              ];
          ];
        executable
          [
            public_name (package_name ^ "-package-uninstall");
            package package_name;
            name "entry_uninstall";
            libraries
              ([ "dkml-package-console.entry"; "cmdliner"; "private_common" ]
              @ dkml_components);
            modules [ "entry_uninstall" ];
            ocamlopt_flags
              [
                List
                  (loglevel_flags
                  @ [
                      Atom ":include";
                      Atom (with_common_dir "console-link-flags.sexp");
                    ]);
              ];
          ];
        executable
          [
            public_name (package_name ^ "-package-setup");
            package package_name;
            name "package_setup";
            modes_byte_exe;
            libraries
              ([ "dkml-package-console.setup"; "cmdliner"; "private_common" ]
              @ dkml_components);
            modules [ "package_setup" ];
          ];
        executable
          [
            public_name (package_name ^ "-package-uninstaller");
            package package_name;
            name "package_uninstaller";
            modes_byte_exe;
            libraries
              ([
                 "dkml-package-console.uninstaller";
                 "cmdliner";
                 "private_common";
               ]
              @ dkml_components);
            modules [ "package_uninstaller" ];
          ];
        install
          [
            section "bin";
            package package_name;
            files
              [
                (* Bytecode is not automatically installed.
                   Sigh: Dune always adds .exe to .bc files. *)
                destination_file ~filename:"package_setup.bc"
                  ~destination:(package_name ^ "-package-setup.bc");
                destination_file ~filename:"package_uninstaller.bc"
                  ~destination:(package_name ^ "-package-uninstaller.bc");
              ];
          ];
        (*
           Validate on a machine that has awk that the executables do not have any
           stub libraries except the ones built for ocamlrun.exe.
           (We do not have a mechanism to distribute stublib DLLs!)
        *)
        rule
          [
            alias "runtest";
            deps
              [
                named_dep ~name:"ps" "package_setup.bc";
                named_dep ~name:"pu" "package_uninstaller.bc";
              ];
            action
              [
                progn
                  [
                    with_stdout_to "package_setup.info.txt"
                      (run [ "ocamlobjinfo"; "%{ps}" ]);
                    with_stdout_to "package_uninstaller.info.txt"
                      (run [ "ocamlobjinfo"; "%{pu}" ]);
                    with_stdout_to "dlls.corrected.txt"
                      (progn
                         [
                           run
                             [
                               "awk";
                               {|/.*:/ {x=0} /Used DLLs:/{x=1; $1="package_setup.bc Used"} x==1 {print}|};
                               "package_setup.info.txt";
                             ];
                           run
                             [
                               "awk";
                               {|/.*:/ {x=0} /Used DLLs:/{x=1; $1="package_uninstaller.bc Used"} x==1 {print}|};
                               "package_uninstaller.info.txt";
                             ];
                         ]);
                    diff_q ~actual:"dlls.txt" ~expected:"dlls.corrected.txt";
                  ];
              ];
          ];
      ]
  in
  let corrected = Fpath.v corrected in
  let output_dir, corrected_base = Fpath.split_base corrected in
  Rresult.R.error_msg_to_invalid_arg
    (let ( let* ) = Rresult.R.bind in
     let* (_ : bool) = Bos.OS.Dir.create output_dir in
     let* z =
       Bos.OS.File.with_oc corrected
         (fun oc () ->
           let fmt = Format.formatter_of_out_channel oc in
           write_dune_inc
             ~output_rel:Fpath.(project_rel_dir // corrected_base)
             fmt dune_inc;
           Ok ())
         ()
     in
     z)

let corrected_t =
  let doc =
    "$(docv) is the output file. Conventionally it should named dune.inc. It \
     can be included in a pre-existing Dune file with the (include dune.inc_) \
     statement."
  in
  Arg.(required & pos 0 (some string) None & info ~docv:"FILE" ~doc [])

let project_root_t =
  let doc = "" in
  Arg.(required & opt (some dir) None & info ~doc [ "project-root" ])

let package_name_t =
  let doc = "" in
  Arg.(required & opt (some string) None & info ~doc [ "package-name" ])

let common_dir_t =
  let doc =
    "The directory that the common files were generated in. Defaults to: ."
  in
  Arg.(required & opt (some dir) (Some ".") & info ~doc [ "common-dir" ])

let setup_log style_renderer level =
  Fmt_tty.setup_std_outputs ?style_renderer ();
  Logs.set_level level;
  Logs.set_reporter (Logs_fmt.reporter ())

let setup_log_t =
  Term.(const setup_log $ Fmt_cli.style_renderer () $ Logs_cli.level ())

let main_t =
  Term.(
    const main $ setup_log_t $ project_root_t $ package_name_t $ common_dir_t
    $ corrected_t)

let () =
  let doc =
    "Print a $(b,dune.inc) that, when included in Dune, will produce an \
     installer generator executable"
  in
  exit Cmd.(eval (v (info "package-dune-of-installer-generator" ~doc) main_t))
