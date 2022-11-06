{ pkgs, tzproxy }:

with pkgs;
with ocamlPackages;
mkShell {
  OCAMLRUNPARAM = "b";
  inputsFrom = [ tzproxy ];
  packages = [ nixfmt utop ocamlformat ocaml findlib dune odoc ocaml-lsp ];
}
