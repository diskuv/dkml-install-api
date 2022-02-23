module Global_context : sig
  type t
  (** the type of the global context *)

  type staging_files_source = Opam_context | Staging_files_dir of string

  val create :
    Dkml_install_register.Component_registry.t ->
    staging_files_source:staging_files_source ->
    t
  (** [create registry ~staging_files_source] creates a global context
      for components in the [registry] with staging files coming from
      [staging_files_source] *)
end

module Interpreter : sig
  type t

  val create :
    Global_context.t -> self_component_name:string -> prefix:string -> t
  (** [create global_ctx ~self_component_name ~prefix] creates an interpreter
      for the component [self_component_name] for installations into
      the [prefix] directory. 
        
      [global_ctx] is the global context from {!Global_context.create}. *)

  val eval : t -> string -> string
  (** [eval interpreter expression] uses the [interpreter] to expand the [expression] *)

  val path_eval : t -> string -> Fpath.t
  (** [path_eval interpreter expression] uses the [interpreter] to expand the [expression]
      into a path. On Windows the path will be a conventional Windows path with
      backslashes instead of forward slashes. *)
end
