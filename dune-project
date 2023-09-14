(lang dune 2.9)
(cram enable)
(generate_opam_files true)

(source (github diskuv/dkml-install-api))

(license Apache-2.0)
(authors "Diskuv, Inc. <opensource+dkml@support.diskuv.com>")
(maintainers "opensource+dkml@support.diskuv.com")

(name dkml-install)
(version 0.5.1)

(package
 (name dkml-install)
 (synopsis "API and registry for DkML installation components")
 (description
  "All DkML installation components implement the interfaces exposed in this API.")
 (depends
  (ocaml (>= 4.08.0))
  (alcotest (and (>= 1.4.0) :with-test))
  (ppx_deriving (>= 5.2.1))
  (result (>= 1.5))
  (astring (>= 0.8.5))
  (bos (>= 0.2.0))
  (cmdliner (>= 1.1.1))
  (fmt (>= 0.8.9))
  (tsort (>= 2.1.0))
  (diskuvbox (and (>= 0.1.1) :with-test))))

(package
 (name dkml-install-runner)
 (synopsis "Runner executable for DkML installation")
 (description
  "The runner executable is responsible for loading and running all DkML installation components.")
 (depends
  (alcotest (and (>= 1.4.0) :with-test))
  (dkml-install (= :version))
  (ppx_expect (>= v0.14.1))
  (astring (>= 0.8.5))
  (bos (>= 0.2.0))
  (cmdliner (>= 1.1.1))
  (fmt (>= 0.8.9))
  (logs (>= 0.7.0))
  (diskuvbox (>= 0.1.1))))

(package
 (name dkml-install-installer)
 (synopsis "Build tools for DkML installers")
 (description
  "Build-time executables that can generate Dune include files which will compile essential end-user executables.")
 (depends
  (alcotest (and (>= 1.4.0) :with-test))
  (dkml-install (= :version))
  (dkml-install-runner (= :version))
  (crunch (>= 3.3.1))))

(package
 (name dkml-package-console)
 (synopsis "Console setup and uninstall executables for DkML installation")
 (description "The setup and uninstall executables are responsible for launching the DkML runners.")
 (depends
  (alcotest (and (>= 1.4.0) :with-test))
  (dkml-install (= :version))
  ; runner/console/bin/dune site requires dkml-install-runner package
  (dkml-install-runner (= :version))
  (diskuvbox (>= 0.1.1))
  (crunch (>= 3.3.1))
  (dkml-component-xx-console (>= 0.1.1))))
