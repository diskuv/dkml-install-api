val get_ok_or_failwith_string : ('a, string) result -> 'a

val get_ok_or_failwith_rresult : ('a, Rresult.R.msg) result -> 'a

val box_err : string -> 'a
