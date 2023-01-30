open Dkml_install_runner.Error_handling.Monad_syntax
module Arg = Cmdliner.Arg
module Cmd = Cmdliner.Cmd
module Term = Cmdliner.Term

let copy_as_is file =
  let content =
    match Code.read file with
    | Some x -> x
    | None -> failwith (Fmt.str "No %s in crunched common_code.ml" file)
  in
  Dkml_install_runner.Error_handling.continue_or_exit
  @@ Dkml_install_runner.Error_handling.map_rresult_error_to_progress
  @@ Dkml_install_runner.Error_handling.continue_or_exit
  @@ Dkml_install_runner.Error_handling.map_rresult_error_to_progress
  @@ Bos.OS.File.with_oc (Fpath.v file)
       (fun oc () ->
         let fmt = Format.formatter_of_out_channel oc in
         Fmt.pf fmt "%s" content;
         Format.pp_print_flush fmt ();
         Ok ())
       ()

let main () =
  let components = Common_installer_generator.ocamlfind () in

  let copy ~target_abi ~components filename =
    let content = Option.get (Code.read filename) in
    Dkml_install_runner.Error_handling.continue_or_exit
    @@ Dkml_install_runner.Error_handling.map_rresult_error_to_progress
    @@ Ml_of_installer_generator_lib.copy_with_templates ~target_abi ~components
         ~output_file:(Fpath.v filename) content
  in

  Dkml_install_runner.Error_handling.continue_or_exit
    (let* target_abi, _fl = Dkml_install_runner.Ocaml_abi.create_v2 () in
     copy_as_is "discover.ml";
     copy_as_is "entry-application.manifest";
     copy ~target_abi ~components "entry_assembly_manifest.ml";
     return ())

let main_t = Term.(const main $ const ())

let () =
  let doc =
    "Writes $(b,.ml) files that are used by dune-of-installer-generator.exe"
  in
  exit
    (Dkml_install_runner.Error_handling.catch_and_exit_on_error ~id:"878ee300"
       (fun () ->
         Cmd.(
           eval ~catch:false (v (info "common-ml-of-installer-generator" ~doc) main_t))))
