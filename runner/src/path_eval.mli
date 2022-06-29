module Global_context : sig
  type t
  (** the type of the global context *)

  val create :
    Dkml_install_register.Component_registry.t ->
    t Dkml_install_api.Forward_progress.t
  (** [create registry] creates a global context for components in the
      [registry] *)
end

module Interpreter : sig
  type t

  val create :
    Global_context.t ->
    self_component_name:string ->
    abi:Dkml_install_api.Context.Abi_v2.t ->
    staging_files_source:Path_location.staging_files_source ->
    prefix:Fpath.t ->
    t Dkml_install_api.Forward_progress.t
  (** [create global_ctx ~self_component_name ~abi ~staging_files_source ~prefix]
      creates an interpreter
      for the component [self_component_name] for installations into
      the [prefix] directory. 
        
      [global_ctx] is the global context from {!Global_context.create}. *)

  val create_minimal :
    self_component_name:string ->
    abi:Dkml_install_api.Context.Abi_v2.t ->
    staging_files_source:Path_location.staging_files_source ->
    prefix:Fpath.t ->
    t Dkml_install_api.Forward_progress.t
  (** [create_minimal ~self_component_name ~abi ~staging_files_source ~prefix]
      creates a "minimal" interpreter with only one [self_component_name]
      component. The interpreter also has access to non-component
      specific variables. *)

  val eval : t -> string -> string
  (** [eval interpreter expression] uses the [interpreter] to expand the [expression] *)

  val path_eval : t -> string -> Fpath.t
  (** [path_eval interpreter expression] uses the [interpreter] to expand the [expression]
      into a path. On Windows the path will be a conventional Windows path with
      backslashes instead of forward slashes. *)
end

module Private : sig
  val mock_default_tmp_dir : Fpath.t

  val mock_interpreter :
    unit -> Interpreter.t Dkml_install_api.Forward_progress.t
end
