(* Load all the available components *)
let () = Sites.Plugins.Plugins.load_all ()

(* Execute the code registered by the components *)
let () =
  match
    Dkml_install_register.Component_registry.eval
      (Dkml_install_register.Component_registry.get ()) ~f:(fun config ->
        let module Cfg = (val config : Dkml_install_api.Component_config) in
        Fmt.pr "Running component %s@\n" Cfg.component_name;
        Result.ok ())
  with
  | Ok () -> ()
  | Error msg -> failwith msg

let () = Fmt.pr "Finished@\n"
