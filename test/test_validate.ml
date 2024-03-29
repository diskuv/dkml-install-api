open Dkml_install_register
open More_testables

let test_uppercase () =
  Alcotest.(check (result unit string_starts_with))
    "result starts with" (Error "[19c415af]")
    (Private.validate
       (module struct
         include Dkml_install_api.Default_component_config

         let component_name = "UPPERCASE"
       end))

let test_lowercase () =
  Alcotest.(check (result unit string_starts_with))
    "result starts with" (Ok ())
    (Private.validate
       (module struct
         include Dkml_install_api.Default_component_config

         let component_name = "lowercase"
       end))

let test_underscore () =
  Alcotest.(check (result unit string_starts_with))
    "result starts with" (Error "[19c415af]")
    (Private.validate
       (module struct
         include Dkml_install_api.Default_component_config

         let component_name = "lower_case"
       end))

let test_dash () =
  Alcotest.(check (result unit string_starts_with))
    "result starts with" (Ok ())
    (Private.validate
       (module struct
         include Dkml_install_api.Default_component_config

         let component_name = "lower-case"
       end))

let () =
  let open Alcotest in
  run "Validate"
    [
      ( "string-case",
        [
          test_case "Upper case" `Quick test_uppercase;
          test_case "Lower case" `Quick test_lowercase;
        ] );
      ( "special-symbols",
        [
          test_case "Underscore" `Quick test_underscore;
          test_case "Dash" `Quick test_dash;
        ] );
    ]
