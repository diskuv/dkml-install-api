open Astring

(** [string_starts_with] tests that the first string is a prefix of the second
    string *)
let string_starts_with =
  Alcotest.testable (Fmt.fmt "%s") (fun s1 s2 -> String.is_prefix ~affix:s1 s2)

let get_success_or_fail = function
  | Dkml_install_api.Forward_progress.Completed ->
      Alcotest.fail "Unexpected 'completed' forward progress"
  | Dkml_install_api.Forward_progress.Continue_progress (a, _fl) -> a
  | Dkml_install_api.Forward_progress.Halted_progress ec ->
      Alcotest.fail (Dkml_install_api.Forward_progress.Exit_code.show ec)
