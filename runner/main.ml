(* Load all the available components *)
let () = Sites.Plugins.Plugins.load_all ()

(* Execute the code registered by the components *)
let () =
  Dkml_install_register.Component_registry.iter
    (Dkml_install_register.Component_registry.get ()) ~f:(fun name _config ->
      Fmt.pr "Running component %s@\n" name)

let () = Fmt.pr "Finished@\n"
