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

      # uri = osuper.uri.overrideAttrs (o: {
      #   propagatedBuildInputs = (with osuper; [ ounit ])
      #     ++ o.propagatedBuildInputs;
      # });

      # piaf = osuper.piaf.overrideAttrs (o: {
      #   src = prev.fetchFromGitHub {
      #     owner = "anmonteiro";
      #     repo = "piaf";
      #     rev = "be16b6752000f24e4bf393ea5e312551ff86b9fd";
      #     sha256 = "sha256-HyhdblCb2p6H1nmme6u6aBx/Rqmyde/9mwjslp9gFX0=";
      #     fetchSubmodules = true;
      #   };
      #   patches = [ ];
      #   doCheck = false;
      #   # propagatedBuildInputs = with osuper; [
      #   #   eio
      #   #   eio_main
      #   #   eio-ssl
      #   #   httpaf-eio
      #   #   h2-eio
      #   #   ipaddr
      #   #   magic-mime
      #   #   multipart_form
      #   #   sendfile
      #   #   uri
      #   # ];
      # });
    })) prev.ocaml-ng;
}
