let get_ok_or_failwith_string = function
  | Ok v -> v
  | Error s ->
      Logs.err (fun l -> l "FATAL: %s" s);
      failwith s

let get_ok_or_failwith_rresult = function
  | Ok v -> v
  | Error msg ->
      Logs.err (fun l -> l "FATAL: %a" Rresult.R.pp_msg msg);
      failwith (Fmt.str "FATAL: %a" Rresult.R.pp_msg msg)

let box_err s =
  Logs.err (fun l -> l "FATAL: %s" s);
  failwith s
