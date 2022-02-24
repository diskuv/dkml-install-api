(lang dune 2.9)
(using dune_site 0.1)

(name dkml-install-api)
(version 0.1.0)

(generate_opam_files true)

(source
 (github diskuv/dkml-install-api))
(license Apache-2.0)
(authors "Diskuv, Inc. <opensource+diskuv-ocaml@support.diskuv.com>")
(maintainers "opensource+diskuv-ocaml@support.diskuv.com")

(package
 (name dkml-install)
 (synopsis "API and registry for Diskuv OCaml (DKML) installation components")
 (description
  "All DKML installation components implement the interfaces exposed in this API.")
 (depends
  (alcotest (and (>= 1.4.0) :with-test))
  (odoc (and (>= 1.5.3) :with-doc))
  (dune (>= 2.9))
  (dune-site (>= 2.9))
  (fmt (>= 0.8.9))
  (astring (>= 0.8.5))
  (tsort (>= 2.1.0))
  (cmdliner (= 1.0.4))))

(package
 (name dkml-install-runner)
 (synopsis "Runner executable for Diskuv OCaml (DKML) installation")
 (description
  "The runner executable is responsible for loading and running all DKML installation components.")
 (sites
  ; <section> <name>
  (lib plugins))
 (depends
  (alcotest (and (>= 1.4.0) :with-test))
  (odoc (and (>= 1.5.3) :with-doc))
  (dkml-install (= :version))
  (dune (>= 2.9))
  (dune-site (>= 2.9))
  (fmt (>= 0.8.9))
  (astring (>= 0.8.5))
  (cmdliner (= 1.0.4))
  (logs (>= 0.7.0))
  (bos (>= 0.2.0))
  (ppx_expect (>= v0.14.1))))
