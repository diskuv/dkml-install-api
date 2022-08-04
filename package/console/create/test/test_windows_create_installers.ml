module Term = Cmdliner.Term

(* Create some demonstration components that are immediately registered *)

let () =
  let reg = Dkml_install_register.Component_registry.get () in
  Dkml_install_register.Component_registry.add_component ~raise_on_error:true
    reg
    (module struct
      include Dkml_install_api.Default_component_config

      let component_name = "offline-test-a"

      (* During installation test-a needs ocamlrun.exe. staging-ocamlrun
         is a pre-existing component that gives you ocamlrun.exe. *)
      let install_depends_on = [ "staging-ocamlrun" ]

      (* During uninstallation test-a doesn't need ocamlrun.exe.

         Often uninstallers just need to delete a directory and other
         small tasks that can be done directly using the install API
         and/or the install API's standard libraries (ex. Bos).

         Currently the console installer and console uninstaller always force a
         dependency on staging-ocamlrun; this may change and other types of
         uninstallers may not have the same behavior.
      *)
      let uninstall_depends_on = []
    end);
  Dkml_install_register.Component_registry.add_component ~raise_on_error:true
    reg
    (module struct
      include Dkml_install_api.Default_component_config

      let component_name = "offline-test-b"

      (* During installation test-b needs test-a *)
      let install_depends_on = [ "staging-ocamlrun"; "offline-test-a" ]

      let uninstall_depends_on = []
    end)

(* Let's also create an entry point for `create_installers.exe` *)
let () =
  Term.(
    exit
    @@ Dkml_package_console_create.create_installers
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
           installation_prefix_camel_case_nospaces_opt = None;
           installation_prefix_kebab_lower_case_opt = None;
         })
