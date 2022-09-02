(lang dune 3.2)

(name tzproxy)

(version 0.1)

(maintainers "infra@marigold.dev")

(generate_opam_files true)

(package
 (name tzproxy)
 (synopsis "TzProxy")
 (description "TzProxy")
 (depends
  (alcotest :with-test)
  (dune
   (and
    :build
    (>= 3.1.1)))
  eio_main
  ))

