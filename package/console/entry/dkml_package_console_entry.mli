val entry :
  install_direction:Dkml_install_register.install_direction ->
  target_abi:Dkml_install_api__Types.Context.Abi_v2.t ->
  unit
(** [entry ~install_direction ~target_abi] is the entry point for the end-user's [target_abi]
    installation or uninstallation (depending on [install_direction]). *)
