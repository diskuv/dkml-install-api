open Dkml_install_api
open Dkml_install_register
open More_testables

let ( >>= ) = Result.bind

let ops = Queue.create ()

module A = struct
  include Default_component_config

  let component_name = "a"

  let depends_on = [ "b" ]

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

  let depends_on = [ "a" ]

  let test () = Queue.add ("test eval " ^ "c") ops
end

let evaluate_in_registry ~eval reg =
  eval reg ~f:(fun cfg ->
      let module Cfg = (val cfg : Component_config) in
      Cfg.test ();
      Result.ok (Fmt.str "(return %s)" Cfg.component_name))
  >>= fun results_lst ->
  Queue.add
    (Fmt.str "results %a" (Fmt.list ~sep:(Fmt.any ", ") Fmt.string) results_lst)
    ops;
  Result.ok (Queue.to_seq ops |> List.of_seq)

let test_eval () =
  let () = Queue.clear ops in
  let () = Component_registry.Private.reset () in
  Alcotest.(check (result (list string) string_starts_with))
    "evaluate in order of dependencies; return results in evaluation order"
    (Result.ok
       [
         "test eval b";
         "test eval a";
         "test eval c";
         "results (return b), (return a), (return c)";
       ])
    (let reg = Component_registry.get () in
     Component_registry.add_component reg (module A);
     Component_registry.add_component reg (module B);
     Component_registry.add_component reg (module C);
     evaluate_in_registry ~eval:Component_registry.eval reg)

let test_reverse_eval () =
  let () = Queue.clear ops in
  let () = Component_registry.Private.reset () in
  Alcotest.(check (result (list string) string_starts_with))
    "evaluate in order of dependencies; return results in evaluation order"
    (Result.ok
       [
         "test eval c";
         "test eval a";
         "test eval b";
         "results (return c), (return a), (return b)";
       ])
    (let reg = Component_registry.get () in
     Component_registry.add_component reg (module A);
     Component_registry.add_component reg (module B);
     Component_registry.add_component reg (module C);
     evaluate_in_registry ~eval:Component_registry.reverse_eval reg)

let test_validate_failure () =
  let () = Queue.clear ops in
  let () = Component_registry.Private.reset () in
  Alcotest.(check (result unit string_starts_with))
    "validate failure when dependency not addded"
    (Result.error "[14b63c08]")
    (let reg = Component_registry.get () in
     Component_registry.add_component reg (module A);
     Component_registry.validate reg)

let test_validate_success () =
  let () = Queue.clear ops in
  let () = Component_registry.Private.reset () in
  Alcotest.(check (result unit string_starts_with))
    "validate success when all dependencies added" (Result.ok ())
    (let reg = Component_registry.get () in
     Component_registry.add_component reg (module A);
     Component_registry.add_component reg (module B);
     Component_registry.add_component reg (module C);
     Component_registry.validate reg)

let () =
  let open Alcotest in
  run "Registry"
    [
      ( "dependency-order",
        [
          test_case "eval" `Quick test_eval;
          test_case "reverse-eval" `Quick test_reverse_eval;
        ] );
      ( "validation",
        [
          test_case "validate-failure" `Quick test_validate_failure;
          test_case "validate-success" `Quick test_validate_success;
        ] );
    ]
