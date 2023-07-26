type t = { all_components : string list }
type phase = Installation | Uninstallation

module StringSet = Set.Make (struct
  type t = string

  let compare = String.compare
end)

let should_debug =
  match Sys.getenv_opt "DKML_INSTALL_GENERATOR_DEBUG" with
  | Some "ON" | Some "1" -> true
  | Some _ | None -> false

let debug f = if should_debug then f Fmt.epr else ()

let create () =
  Fmt.epr "Initializing findlib: ";
  Findlib.init ();
  Fmt.epr "done.@.";
  (* A. Get every package in the ocamlfind universe / opam switch that
     could possibly be a component.

     Our technique is to use the definition of component:
     - a component is a package that registers itself with DkML Install API
     - a component has a META with the field [dkml_install] set
     to "component"

     Since we are using ocamlfind, component packages must be within the
     transitive *users* of [dkml-install.register]. Then we'll filter
     down to the correct subset which has the [dkml_install] META field.

     Essentially:
     ["ocamlfind query -format '%p' -d -r dkml-install.register"]
  *)
  let superset_all_components =
    Fl_package_base.package_users ~preds:[] [ "dkml-install.register" ]
  in
  Fmt.epr "@[<hov 2>Descendants of dkml-install.register:@ @[%a@]@]@."
    Fmt.(list ~sep:sp string)
    superset_all_components;
  let all_components =
    List.map
      (fun component -> Fl_package_base.query component)
      superset_all_components
    |> List.filter_map (fun { Fl_package_base.package_name; package_defs; _ } ->
           match Fl_metascanner.lookup "dkml_install" [] package_defs with
           | "component" -> Some package_name
           | _other_package -> None
           | exception Not_found -> None)
  in
  Fmt.epr
    "@[<hov 2>Descendant subset that has dkml_install=component in META:@ \
     @[%a@]@]@."
    Fmt.(list ~sep:sp string)
    all_components;
  { all_components }

let ocamlfind { all_components } ~phase ~desired_components () =
  let depends_on =
    match phase with
    | Installation -> "install_depends_on"
    | Uninstallation -> "uninstall_depends_on"
  in
  let uniq = List.sort_uniq String.compare in
  let info_fmt v =
    Fmt.epr ("[%s] " ^^ v)
      (match phase with
      | Installation -> "Installation"
      | Uninstallation -> "Uninstallation")
  in
  let info f = f info_fmt in

  (* B. We want to the transitive component dependencies of the
     installer (or uninstaller) components.

     We'll need to de-duplicate the results since we have N desired
     installer components.
  *)
  let transitive_components =
    let visited = ref [] in
    let rec helper remaining =
      match remaining with
      | [] -> []
      | lib :: tl when List.mem lib !visited ->
          debug (fun l -> l "[visited]  library = %s@." lib);
          helper tl
      | lib :: tl -> (
          match Fl_package_base.query lib with
          | exception Fl_package_base.No_such_package (x, y) ->
              Fmt.epr
                "WARNING: findlib gave No_such_package (%s, %s). Skipping %s@."
                x y lib;
              helper tl
          | exception _ ->
              Fmt.epr "Unknown exception A@.";
              helper tl
          | { package_defs; _ } ->
              (* Maintain guard against infinite recursion *)
              visited := lib :: !visited;
              let depends_on_values =
                match Fl_metascanner.lookup depends_on [] package_defs with
                | exception Not_found -> []
                | exception _ ->
                    Fmt.epr "Unknown exception B@.";
                    []
                | depends_on_value ->
                    Astring.String.cuts ~empty:false ~sep:" " depends_on_value
              in
              debug (fun l ->
                  l "[%s]  depends_on = %a@." lib
                    Fmt.(Dump.list string)
                    depends_on_values);
              (lib :: helper depends_on_values) @ helper tl)
    in
    let desired_pkgs =
      List.map
        (fun component -> "dkml-component-" ^ component)
        desired_components
    in
    helper desired_pkgs |> uniq
  in
  info (fun l ->
      l "@[<hov 2>Ancestors of %a:@ @[%a@]@]@."
        Fmt.(list ~sep:sp string)
        desired_components
        Fmt.(list ~sep:sp string)
        transitive_components);

  (* C. We want the intersection of A and B. That is, the packages that both
     could possibly be components (A) _and_ are a transitive dependency of
     the desired components (B).
  *)
  let refined_components =
    StringSet.(
      inter (of_list all_components) (of_list transitive_components) |> elements)
  in

  (* D. We want the actual component names, not the full package name.

     We rely on the naming requirement that component packages are named
     ["dkml-component-COMPONENT_NAME"].
  *)
  let components =
    let prefix = "dkml-component-" in
    List.filter (Astring.String.is_prefix ~affix:prefix) refined_components
    |> List.map (fun s ->
           Astring.String.(sub ~start:(String.length prefix) s |> Sub.to_string))
    |> List.sort String.compare
  in
  info (fun l ->
      l
        "@[<hov 2>Desired components and their transitive dependencies:@ \
         @[%a@]@]@."
        Fmt.(list ~sep:sp string)
        components);
  components
