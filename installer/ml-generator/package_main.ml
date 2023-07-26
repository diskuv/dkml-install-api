open Dkml_install_runner.Error_handling.Monad_syntax
module Arg = Cmdliner.Arg
module Cmd = Cmdliner.Cmd
module Term = Cmdliner.Term

let copy_as_is file =
  let content =
    match Code.read file with
    | Some x -> x
    | None -> failwith (Fmt.str "No %s in crunched package_code.ml" file)
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

let main install_components uninstall_components () =
  let cig = Common_installer_generator.create () in
  let install_components =
    Common_installer_generator.ocamlfind cig ~phase:Installation
      ~desired_components:install_components ()
  in
  let uninstall_components =
    Common_installer_generator.ocamlfind cig ~phase:Uninstallation
      ~desired_components:uninstall_components ()
  in
  let both_components =
    install_components @ uninstall_components |> List.sort_uniq String.compare
  in

  let copy ~target_abi ~components filename =
    let content = Option.get (Code.read filename) in
    Dkml_install_runner.Error_handling.continue_or_exit
    @@ Dkml_install_runner.Error_handling.map_rresult_error_to_progress
    @@ Ml_of_installer_generator_lib.copy_with_templates ~target_abi ~components
         ~output_file:(Fpath.v filename) content
  in

  Dkml_install_runner.Error_handling.continue_or_exit
    (let* target_abi, _fl = Dkml_install_runner.Ocaml_abi.create_v2 () in
     copy ~target_abi ~components:install_components "entry_install.ml";
     copy ~target_abi ~components:uninstall_components "entry_uninstall.ml";
     copy ~target_abi ~components:both_components "create_installers.ml";
     copy ~target_abi ~components:both_components "runner_admin.ml";
     copy ~target_abi ~components:both_components "runner_user.ml";
     copy ~target_abi ~components:install_components "package_setup.ml";
     copy ~target_abi ~components:uninstall_components "package_uninstaller.ml";
     return ())

let install_components_t =
  let doc =
    "A component to add to the set of desired components that run during \
     installation. Only desired components and their transitive dependencies \
     are packaged. May be repeated. At least one component must be specified."
  in
  Arg.(non_empty & opt_all string [] & info [ "install" ] ~doc)

let uninstall_components_t =
  let doc =
    "A component to add to the set of desired components that run during \
     uninstallation. Only desired components and their transitive dependencies \
     are packaged. May be repeated."
  in
  Arg.(value & opt_all string [] & info [ "uninstall" ] ~doc)

let main_t =
  Term.(const main $ install_components_t $ uninstall_components_t $ const ())

let () =
  Logs.set_reporter (Logs.format_reporter ());
  let doc =
    "Writes $(b,.ml) files that are used by dune-of-installer-generator.exe"
  in
  exit
    (Dkml_install_runner.Error_handling.catch_and_exit_on_error ~id:"878ee300"
       (fun () ->
         Cmd.(
           eval ~catch:false
             (v (info "package-ml-of-installer-generator" ~doc) main_t))))
