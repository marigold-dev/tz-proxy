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

      piaf = osuper.piaf.overrideAttrs (o: {
        src = prev.fetchFromGitHub {
          owner = "anmonteiro";
          repo = "piaf";
          rev = "77f3f539f84b82cf049c20678af1898484e0ae84";
          sha256 = "sha256-eHYHr6XEefKvQyE48GW9qA1P508YrWwsb1Ov9tX25V8=";
          fetchSubmodules = true;
        };
        patches = [ ];
        propagatedBuildInputs = with osuper; [
          eio
          multipart_form
          sendfile
          ipaddr
          uri
          ssl
          magic-mime
          eio-ssl
          httpaf-eio
          h2-eio
        ];
      });

    })) prev.ocaml-ng;
}
