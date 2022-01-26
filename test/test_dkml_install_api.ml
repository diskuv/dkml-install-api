open Dkml_install_register
open More_testables

let test_add_once () =
  Alcotest.(check (result unit string_starts_with))
    "no errors" (Result.ok ())
    (let reg = Component_registry.get () in
     Component_registry.add_component reg
       (module struct
         let component_name = "add_once"
       end))

let test_add_twice () =
  Alcotest.(check (result unit string_starts_with))
    "fail to add same component name"
    (Result.error "[debe504f]")
    (let reg = Component_registry.get () in
     let ( >>= ) = Result.bind in
     Component_registry.add_component reg
       (module struct
         let component_name = "add_twice"
       end)
     >>= fun () ->
     Component_registry.add_component reg
       (module struct
         let component_name = "add_twice"
       end))

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
