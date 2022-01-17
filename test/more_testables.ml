open Astring

(** [string_starts_with] tests that the first string is a prefix of the second
    string *)
let string_starts_with =
  Alcotest.testable (Fmt.fmt "%s") (fun s1 s2 -> String.is_prefix ~affix:s1 s2)
