type t
(** The type of installer generator *)

type phase = Installation | Uninstallation

val create : unit -> t
(** Create the installer generator *)

val ocamlfind :
  t -> phase:phase -> desired_components:string list -> unit -> string list
(** [ocamlfind ~phase ~desired_components ()] uses an ["ocamlfind"]-based
    algorithm to get the desired DkML Install API components
    ([desired_components]) and their transitive dependencies.

    [phase] describes which phase (installation or uninstallation) the
    components are being used.

    A lexographic sort is performed for stability. *)
