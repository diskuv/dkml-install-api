open Cmdliner
open Sexplib0
open Bos

(* {1 Directories} *)

let fpath_pp_mixed fmt v =
  let s = Fmt.str "%a" Fpath.pp v in
  Fmt.pf fmt "%s" (String.map (function '\\' -> '/' | c -> c) s)

let pwd () = Rresult.R.error_msg_to_invalid_arg (OS.Dir.current ())

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
  Fmt.pf fmt "; Auto-generated by dune-of-installer-generator.exe.@\n";
  Fmt.pf fmt "; Do not edit unless need to regenerate!@\n";
  Fmt.pf fmt
    "; When regenerating, erase **all** content from this file, save the file, \
     and then run:@\n";
  Fmt.pf fmt ";   dune build %a --auto-promote@\n" fpath_pp_mixed output_rel;
  Fmt.pf fmt "%a@\n" Fmt.(list ~sep:(any "@\n@\n") Sexp.pp_hum) dune_inc;
  Format.pp_print_flush fmt ()

let main () project_root corrected =
  let components = Common_installer_generator.ocamlfind () in
  let dkml_components = List.map (fun s -> "dkml-component-" ^ s) components in
  let project_rel_dir = project_rel_dir project_root in
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
            name "discover";
            libraries [ "dune.configurator"; "bos"; "fpath" ];
            modules [ "discover" ];
          ];
        rule
          [
            targets [ "admin-link-flags.sexp"; "console-link-flags.sexp" ];
            deps
              [
                named_dep ~name:"discover" "discover.exe";
                Atom "entry-application.manifest";
                Atom "entry.assembly.manifest";
              ];
            action [ run [ "%{discover}" ] ];
          ];
        executable
          [
            public_name "dkml-install-user-runner";
            name "runner_user";
            modules [ "runner_user" ];
            libraries ([ "dkml-install-runner.user" ] @ dkml_components);
          ];
        executable
          [
            public_name "dkml-install-admin-runner";
            name "runner_admin";
            modules [ "runner_admin" ];
            ocamlopt_flags
              [
                List
                  (loglevel_flags
                  @ [ Atom ":include"; Atom "admin-link-flags.sexp" ]);
              ];
            libraries ([ "dkml-install-runner.admin" ] @ dkml_components);
          ];
        executable
          [
            public_name "dkml-install-create-installers";
            name "create_installers";
            libraries
              ([ "dkml-package-console.create"; "cmdliner"; "private_common" ]
              @ dkml_components);
            modules [ "create_installers" ];
          ];
        executable
          [
            public_name "dkml-install-package-entry";
            name "entry_main";
            libraries
              ([ "dkml-package-console.entry"; "cmdliner"; "private_common" ]
              @ dkml_components);
            modules [ "entry_main" ];
            ocamlopt_flags
              [
                List
                  (loglevel_flags
                  @ [ Atom ":include"; Atom "console-link-flags.sexp" ]);
              ];
          ];
        executable
          [
            name "entry_assembly_manifest";
            libraries [ "dkml-package-console.common"; "fmt" ];
            modules [ "entry_assembly_manifest" ];
          ];
        rule
          [
            target "entry.assembly.manifest";
            action
              [
                with_stdout_to "%{target}"
                  (run [ "%{exe:entry_assembly_manifest.exe}" ]);
              ];
          ];
        executable
          [
            name "package_setup";
            modes_byte_exe;
            libraries
              ([ "dkml-package-console.setup"; "cmdliner"; "private_common" ]
              @ dkml_components);
            modules [ "package_setup" ];
          ];
        executable
          [
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
            files
              [
                (* Sigh. Dune always adds .exe to .bc files. *)
                destination_file ~filename:"package_setup.bc"
                  ~destination:"dkml-install-package-setup.bc";
                destination_file ~filename:"package_uninstaller.bc"
                  ~destination:"dkml-install-package-uninstaller.bc";
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
            (* target "dlls.corrected.txt"; *)
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
     let* (_ : bool) = OS.Dir.create output_dir in
     let* z =
       OS.File.with_oc corrected
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

let setup_log style_renderer level =
  Fmt_tty.setup_std_outputs ?style_renderer ();
  Logs.set_level level;
  Logs.set_reporter (Logs_fmt.reporter ())

let setup_log_t =
  Term.(const setup_log $ Fmt_cli.style_renderer () $ Logs_cli.level ())

let main_t = Term.(const main $ setup_log_t $ project_root_t $ corrected_t)

let () =
  let doc =
    "Print a $(b,dune.inc) that, when included in Dune, will produce an \
     installer generator executable"
  in
  Term.(exit @@ eval (main_t, info "dune-of-installer-generator" ~doc))
