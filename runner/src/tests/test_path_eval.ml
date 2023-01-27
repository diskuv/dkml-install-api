open Dkml_install_runner
open Path_eval
open Path_eval.Private
open More_testables

let fpath = Alcotest.testable Fpath.pp Fpath.equal
let fpath_is_prefix = Alcotest.testable Fpath.pp Fpath.is_prefix

let () =
  Alcotest.(
    run "path_eval"
      [
        ( "",
          [
            ( "",
              `Quick,
              fun () ->
                let r =
                  Interpreter.eval
                    (get_success_or_fail @@ mock_interpreter ())
                    "%{components:all}%"
                in
                check string
                  "%{components:all}% are all the available components" r
                  "ocamlrun component_under_test" );
            ( "",
              `Quick,
              fun () ->
                let r () =
                  ignore
                    (Interpreter.path_eval
                       (get_success_or_fail @@ mock_interpreter ())
                       "%{components:all}%")
                in
                check_raises
                  "%{components:all}% is not available with path_eval"
                  (Failure
                     "There was at least one unresolved expression: \
                      %{components:all}%. Only the following components are \
                      visible: \n\
                      [tmp; prefix; _:share-generic; _:share-abi; \
                      ocamlrun:share-generic;\n\
                     \ ocamlrun:share-abi]")
                  r );
            ( "",
              `Quick,
              fun () ->
                let r =
                  Interpreter.path_eval
                    (get_success_or_fail @@ mock_interpreter ())
                    "%{tmp}%"
                in
                check fpath_is_prefix
                  "%{tmp}% is a prefix of the temp directory"
                  mock_default_tmp_dir r );
            ( "",
              `Quick,
              fun () ->
                let r =
                  Interpreter.eval
                    (get_success_or_fail @@ mock_interpreter ())
                    "%{name}%"
                in
                check string "%{name}% is the component under test" r
                  "component_under_test" );
            ( "",
              `Quick,
              fun () ->
                let r =
                  Interpreter.path_eval
                    (get_success_or_fail @@ mock_interpreter ())
                    "%{prefix}%"
                in
                check fpath "%{prefix}% is the installation prefix" r
                  (Fpath.v "/test/prefix") );
            ( "",
              `Quick,
              fun () ->
                let r =
                  Interpreter.path_eval
                    (get_success_or_fail @@ mock_interpreter ())
                    "%{prefix}%/bin"
                in
                check fpath
                  "%{prefix}%/bin is the bin/ folder under the installation \
                   prefix"
                  r
                  (Fpath.v "/test/prefix/bin") );
            ( "",
              `Quick,
              fun () ->
                let r =
                  Interpreter.path_eval
                    (get_success_or_fail @@ mock_interpreter ())
                    "%{ocamlrun:share-generic}%"
                in
                check fpath
                  "%{ocamlrun:share-generic}% is the staging-files/generic of \
                   the ocamlrun component"
                  r
                  (Fpath.v "/test/staging-files/ocamlrun/generic") );
            ( "",
              `Quick,
              fun () ->
                let r =
                  Interpreter.path_eval
                    (get_success_or_fail @@ mock_interpreter ())
                    "%{ocamlrun:share-abi}%"
                in
                check fpath
                  "%{ocamlrun:share-abi}% is the staging-files/<abi> of the \
                   ocamlrun component"
                  r
                  (Fpath.v "/test/staging-files/ocamlrun/windows_x86") );
            ( "",
              `Quick,
              fun () ->
                let r =
                  Interpreter.path_eval
                    (get_success_or_fail @@ mock_interpreter ())
                    "%{_:share-abi}%"
                in
                check fpath
                  "%{_:share-abi}% is the staging-files/<abi> of the component \
                   under test"
                  r
                  (Fpath.v
                     "/test/staging-files/component_under_test/windows_x86") );
          ] );
      ])
