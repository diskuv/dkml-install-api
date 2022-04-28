open Cmdliner

(* Create some demonstration components that are immediately registered *)

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

(* Let's also create an entry point for `create_installers.exe` *)
let () =
  Term.(
    exit
    @@ Dkml_package_console_setup.create_installers
         {
           legal_name = "Legal Name";
           common_name_full = "Common Name";
           common_name_camel_case_nospaces = "CommonName";
           common_name_kebab_lower_case = "common-name";
         }
         {
           name_full = "Full Name";
           name_camel_case_nospaces = "FullName";
           name_kebab_lower_case = "full-name";
         })
