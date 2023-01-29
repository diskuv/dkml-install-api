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
  Fmt.pf fmt "; Auto-generated by common-dune-of-installer-generator.exe.@\n";
  Fmt.pf fmt "; Do not edit unless need to regenerate!@\n";
  Fmt.pf fmt
    "; When regenerating, erase **all** content from this file, save the file, \
     and then run:@\n";
  Fmt.pf fmt ";   dune clean@\n";
  Fmt.pf fmt ";   dune build '@%a/gen-dkml' --auto-promote@\n" fpath_pp_mixed
    output_reldir;
  Fmt.pf fmt "%a@\n" Fmt.(list ~sep:(any "@\n@\n") Sexp.pp_hum) dune_inc;
  Format.pp_print_flush fmt ()

let main () project_root corrected =
  let project_rel_dir = project_rel_dir project_root in
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
            targets
              [
                "admin-link-flags.sexp";
                "user-link-flags.sexp";
                "console-link-flags.sexp";
              ];
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
            name "entry_assembly_manifest";
            libraries [ "dkml-package-console.common"; "private_common"; "fmt" ];
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
  exit Cmd.(eval (v (info "dune-of-installer-generator" ~doc) main_t))
