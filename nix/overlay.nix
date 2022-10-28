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
      #     rev = "cd3c040e04557cd38783aa5ec2ce144f8610e2f2";
      #     sha256 = "sha256-Gl1emTfZE9UDEW5VDH68NwvYzdemxFMiu3Dx097uh9M=";
      #     fetchSubmodules = true;
      #   };
      #   patches = [ ];
      #   doCheck = false;
      #   propagatedBuildInputs = with osuper; [
      #     websocketaf
      #     eio
      #     eio_main
      #     eio-ssl
      #     httpaf-eio
      #     h2-eio
      #     ipaddr
      #     magic-mime
      #     multipart_form
      #     sendfile
      #     uri
      #   ];
      # });
    })) prev.ocaml-ng;
}
