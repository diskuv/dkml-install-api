(** [load_all] loads all the DKML install plugins using Dynlink.

    The authoritative list of plugins is
    ["<opam lib>/dkml-install-runner/plugins/<plugin name>/META"],
    which is typically populated by Dune's "dune-site" package.

    Each ["META"] contains a line like
    {[
      requires = "dkml-component-network-ocamlcompiler"
    ]}

    The value of "requires" is the name of a package that will be
    loaded during [load_all ()], and must contain either of the following:
    {[
      "<opam lib>/<requires name>/<requires name>.cmxa"
      "<opam lib>/<requires name>/<requires name>.cma"
    ]}
    
    *)
let load_all () = Sites.Plugins.Plugins.load_all ()
