module StringSet = Set.Make (struct
  type t = string

  let compare = String.compare
end)

let should_debug =
  match Sys.getenv_opt "DKML_INSTALL_GENERATOR_DEBUG" with
  | Some "ON" | Some "1" -> true
  | Some _ | None -> false

let debug f = if should_debug then f Fmt.epr else ()

(** [ocamlfind ~desired_components ()] uses an ["ocamlfind"]-based
    algorithm to get the desired DkML Install API components
    ([desired_components]) and their transitive dependencies.

    A lexographic sort is performed for stability. *)
let ocamlfind ~desired_components () =
  Fmt.epr "Initializing findlib: ";
  Findlib.init ();
  Fmt.epr "done.@.";

  let uniq = List.sort_uniq String.compare in

  (* A. Get every package in the ocamlfind universe / opam switch that
     could possibly be a component.

     Our technique is to use the definition of component:
     a component is a package that registers itself with DkML Install API

     Since we are using ocamlfind, component packages must be within the
     transitive *users* of [dkml-install.register]. We'll get more than
     we want though (ie. a superset).

     Essentially:
     ["ocamlfind query -format '%p' -d -r dkml-install.register"]
  *)
  let superset_all_components =
    Fl_package_base.package_users ~preds:[] [ "dkml-install.register" ]
  in
  Fmt.epr "@[<hov 2>Descendants of dkml-install.register:@ @[%a@]@]@."
    Fmt.(list ~sep:sp string)
    superset_all_components;

  (* B. We want to restrict ourselves to just the components that are
     desired by the installer (and their transitive component dependencies).

     Since we are using ocamlfind, these desired packages are _mostly_ within
     the transitive *requirements* of the installer components. The edge case
     is that a transitive package may be ["dkml-component-COMPONENT_A.api"];
     we must "follow" the API package and visit ["dkml-component-COMPONENT_A"]
     as well.

     We'll get more than we want though (ie. a superset).

     Essentially:
     ["ocamlfind query -format '%p' -r dkml-component-<needed_by_installer1>"]
     ["ocamlfind query -format '%p' -r dkml-component-<needed_by_installerN>"]

     We'll need to de-duplicate the results since we have N desired
     installer components, plus expansions of any .api libraries.
  *)
  let superset_desired_and_required_components =
    let visited = ref [] in
    let requires plain_lib =
      if List.mem plain_lib !visited then []
      else (
        (* Maintain guard against infinite recursion *)
        visited := plain_lib :: !visited;
        (* Only if we haven't processed the library do we ask for more *)
        let candidates = Fl_package_base.requires ~preds:[] plain_lib in
        (* Findlib returns [plain_lib] in addition to the actual requirements.
           Get rid of the [plain_lib]. *)
        List.filter (Fun.negate (String.equal plain_lib)) candidates)
    in
    let rec helper remaining =
      let expand plain_lib =
        let descent_candidates = requires plain_lib in
        debug (fun l ->
            l "@[           (expand)  %a@]@."
              Fmt.(Dump.list string)
              descent_candidates);
        [ plain_lib ] :: helper descent_candidates |> List.flatten |> uniq
      in
      match remaining with
      | [] -> []
      | lib :: tl -> (
          (* Is dotted library? *)
          match String.index_opt lib '.' with
          | None ->
              (* Plain library like dkml-component-COMPONENT_A *)
              debug (fun l -> l "[plain]  library = %s@." lib);
              let expanded_libs = expand lib in
              debug (fun l ->
                  l "[plain]  expanded(%s)= %a@." lib
                    Fmt.(Dump.list string)
                    expanded_libs);
              expanded_libs :: helper tl
          | Some index_first_dot ->
              (* Dotted library like dkml-component-COMPONENT_A.api? *)
              let plain_lib = String.sub lib 0 index_first_dot in
              debug (fun l -> l "[dotted] library = %s@." lib);
              debug (fun l -> l "[dotted] plain library = %s@." plain_lib);
              (* Recursively find what the plain library dependencies are *)
              let expanded_libs = expand plain_lib in
              debug (fun l ->
                  l "[dotted] expanded(%s) = %a@." plain_lib
                    Fmt.(Dump.list string)
                    expanded_libs);
              expanded_libs :: helper tl)
    in
    let desired_pkgs =
      List.map
        (fun component -> "dkml-component-" ^ component)
        desired_components
    in
    helper desired_pkgs |> List.flatten |> uniq
  in
  Fmt.epr "@[<hov 2>Ancestors of %a:@ @[%a@]@]@."
    Fmt.(list ~sep:sp string)
    desired_components
    Fmt.(list ~sep:sp string)
    superset_desired_and_required_components;

  (* C. We want the intersection of A and B. That is, the packages that both
     could possibly be components (A) _and_ are a transitive dependency of
     the desired components (B).

     This still has too more than we want.
  *)
  let superset_refined_sorted_components =
    StringSet.(
      inter
        (of_list superset_all_components)
        (of_list superset_desired_and_required_components)
      |> elements)
  in

  (* D. We want the refined set of packages (C) to be only real components.

     We rely on the naming requirement that component packages are named
     ["dkml-component-COMPONENT_NAME"].
  *)
  let components =
    let prefix = "dkml-component-" in
    List.filter
      (Astring.String.is_prefix ~affix:prefix)
      superset_refined_sorted_components
    |> List.map (fun s ->
           Astring.String.(sub ~start:(String.length prefix) s |> Sub.to_string))
    |> List.sort String.compare
  in
  Fmt.epr
    "@[<hov 2>Desired components and their transitive dependencies:@ @[%a@]@]@."
    Fmt.(list ~sep:sp string)
    components;
  components
