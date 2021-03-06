open Dkml_install_register
open More_testables

let test_add_once () =
  Alcotest.(check unit)
    "no errors" ()
    (let reg = Component_registry.get () in
     Component_registry.add_component reg
       (module struct
         include Dkml_install_api.Default_component_config

         let component_name = "add-once"
       end))

let test_add_twice () =
  Alcotest.(check string_starts_with)
    "fail to add same component name" "FATAL [debe504f]"
    (let reg = Component_registry.get () in
     Component_registry.add_component ~raise_on_error:true reg
       (module struct
         include Dkml_install_api.Default_component_config

         let component_name = "add-twice"
       end);
     try
       Component_registry.add_component ~raise_on_error:true reg
         (module struct
           include Dkml_install_api.Default_component_config

           let component_name = "add-twice"
         end);
       "Was supposed to raise an exception, but didn't"
     with Invalid_argument msg -> msg)

let () =
  let open Alcotest in
  run "Dkml_install_api"
    [
      ( "basic",
        [
          test_case "Add once" `Quick test_add_once;
          test_case "Add twice" `Quick test_add_twice;
        ] );
    ]
