open Dkml_install_api
open Dkml_install_register
open More_testables

let ( let* ) = Forward_progress.bind

let return = Forward_progress.return

let fatallog = Dkml_install_api.Forward_progress.stderr_fatallog

let ops = Queue.create ()

module A = struct
  include Default_component_config

  let component_name = "a"

  let install_depends_on = [ "b" ]

  let test () = Queue.add ("test eval " ^ "a") ops
end

module B = struct
  include Default_component_config

  let component_name = "b"

  let test () = Queue.add ("test eval " ^ "b") ops
end

module C = struct
  include Default_component_config

  let component_name = "c"

  let install_depends_on = [ "a" ]

  let test () = Queue.add ("test eval " ^ "c") ops
end

let evaluate_in_registry ~eval reg =
  let* results_lst, fl =
    eval reg
      ~f:(fun cfg ->
        let module Cfg = (val cfg : Component_config) in
        Cfg.test ();
        return
          ( Fmt.str "(return %s)" Cfg.component_name,
            Dkml_install_api.Forward_progress.stderr_fatallog ))
      ~fl:Dkml_install_api.Forward_progress.stderr_fatallog
  in
  Queue.add
    (Fmt.str "results %a" (Fmt.list ~sep:(Fmt.any ", ") Fmt.string) results_lst)
    ops;
  return (Queue.to_seq ops |> List.of_seq, fl)

let test_install_eval selector () =
  let () = Queue.clear ops in
  let () = Component_registry.Private.reset () in
  Alcotest.(check (list string_starts_with))
    "evaluate in order of dependencies; return results in evaluation order"
    [
      "test eval b";
      "test eval a";
      "test eval c";
      "results (return b), (return a), (return c)";
    ]
    (let reg = Component_registry.get () in
     Component_registry.add_component ~raise_on_error:true reg (module A);
     Component_registry.add_component ~raise_on_error:true reg (module B);
     Component_registry.add_component ~raise_on_error:true reg (module C);
     More_testables.get_success_or_fail
     @@ evaluate_in_registry ~eval:(Component_registry.install_eval ~selector) reg)

let test_uninstall_eval selector () =
  let () = Queue.clear ops in
  let () = Component_registry.Private.reset () in
  Alcotest.(check (list string_starts_with))
    "evaluate in order of dependencies; return results in evaluation order"
    [
      "test eval c";
      "test eval a";
      "test eval b";
      "results (return c), (return a), (return b)";
    ]
    (let reg = Component_registry.get () in
     Component_registry.add_component ~raise_on_error:true reg (module A);
     Component_registry.add_component ~raise_on_error:true reg (module B);
     Component_registry.add_component ~raise_on_error:true reg (module C);
     More_testables.get_success_or_fail
     @@ evaluate_in_registry
          ~eval:(Component_registry.uninstall_eval ~selector)
          reg)

let test_validate_failure () =
  let () = Queue.clear ops in
  let () = Component_registry.Private.reset () in
  Alcotest.(check string_starts_with)
    "validate failure when dependency not addded" "FATAL [14b63c08]"
    (let reg = Component_registry.get () in
     Component_registry.add_component ~raise_on_error:true reg (module A);
     try
       Component_registry.validate ~raise_on_error:true reg;
       "expected to raise an exception but didn't"
     with Invalid_argument s -> s)

let test_validate_success () =
  let () = Queue.clear ops in
  let () = Component_registry.Private.reset () in
  Alcotest.(check unit)
    "validate success when all dependencies added" ()
    (let reg = Component_registry.get () in
     Component_registry.add_component ~raise_on_error:true reg (module A);
     Component_registry.add_component ~raise_on_error:true reg (module B);
     Component_registry.add_component ~raise_on_error:true reg (module C);
     Component_registry.validate ~raise_on_error:true reg)

let () =
  let open Alcotest in
  run "Registry"
    [
      ( "dependency-order all",
        [
          test_case "install_eval" `Quick (test_install_eval All_components);
          test_case "uninstall_eval" `Quick (test_uninstall_eval All_components);
        ] );
      ( "dependency-order select c",
        let selector =
          Component_registry.Just_named_components_plus_their_dependencies
            [ "c" ]
        in
        [
          test_case "eval" `Quick (test_install_eval selector);
          test_case "reverse-eval" `Quick (test_uninstall_eval selector);
        ] );
      ( "validation",
        [
          test_case "validate-failure" `Quick test_validate_failure;
          test_case "validate-success" `Quick test_validate_success;
        ] );
    ]
