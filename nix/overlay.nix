final: prev:
let
  disableCheck = package: package.overrideAttrs (o: { doCheck = false; });
  addCheckInputs = package:
    package.overrideAttrs ({ buildInputs ? [ ], checkInputs, ... }: {
      buildInputs = buildInputs ++ checkInputs;
    });
in {
  ocaml-ng = builtins.mapAttrs (_: ocamlVersion:
    ocamlVersion.overrideScope' (oself: osuper: {
      alcotest = osuper.alcotest.overrideAttrs (o: {
        propagatedBuildInputs =
          prev.lib.lists.remove osuper.uuidm o.propagatedBuildInputs;
      });

      eio_main = osuper.eio_main.overrideAttrs
        (_: { propagatedBuildInputs = with osuper; [ eio_luv ]; });

      multipart_form = osuper.multipart_form.overrideAttrs (o: {
        propagatedBuildInputs = (with osuper; [ alcotest ])
          ++ o.propagatedBuildInputs;
      });

      uri = osuper.uri.overrideAttrs (o: {
        propagatedBuildInputs = (with osuper; [ ounit ])
          ++ o.propagatedBuildInputs;
      });

      piaf = osuper.piaf.overrideAttrs (o: {
        src = prev.fetchFromGitHub {
          owner = "anmonteiro";
          repo = "piaf";
          rev = "2e5cb20365beb49f3498fa95df73b54c27eba765";
          sha256 = "sha256-SL4Z3QMdTUlQNRoeYKLffPgtVXWNEh8ATZmspXR/iUg=";
          fetchSubmodules = true;
        };
        patches = [ ];
        doCheck = false;
        propagatedBuildInputs = with osuper; [
          websocketaf
          eio
          eio_main
          eio-ssl
          httpaf-eio
          h2-eio
          ipaddr
          magic-mime
          multipart_form
          sendfile
          uri
        ];
      });
    })) prev.ocaml-ng;
}
