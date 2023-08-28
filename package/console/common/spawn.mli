val spawn :
  ?err_ok:bool -> Bos.Cmd.t -> unit Dkml_install_api.Forward_progress.t

val spawn_out :
  err_ok:bool option -> Bos.Cmd.t -> string Dkml_install_api.Forward_progress.t
