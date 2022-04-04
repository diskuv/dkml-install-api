let get_ok_or_failwith_string = function
  | Ok v -> v
  | Error s ->
      Logs.err (fun l -> l "FATAL: %s" s);
      failwith s

let box_err s =
  Logs.err (fun l -> l "FATAL: %s" s);
  failwith s
