open Cmdliner

(* Create a test component *)

let () =
  let reg = Dkml_install_register.Component_registry.get () in
  Dkml_install_register.Component_registry.add_component reg
    (module struct
      include Dkml_install_api.Default_component_config

      let component_name = "offline-test1"
    end);
  Dkml_install_register.Component_registry.add_component reg
    (module struct
      include Dkml_install_api.Default_component_config

      let component_name = "staging-ocamlrun"
    end)

(* Now do the normal create_installers *)
let () = Term.(exit @@ Dkml_package_console_setup.create_installers ())
