{ pkgs, tzproxy }:

with pkgs;
with ocamlPackages;
mkShell {
  OCAMLRUNPARAM = "o=40";
  inputsFrom = [ tzproxy ];
  packages = [ nixfmt utop ocamlformat ocaml findlib dune odoc ocaml-lsp ];
}
