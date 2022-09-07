{ pkgs, tzproxy }:

with pkgs;
with ocamlPackages;
mkShell {
  inputsFrom = [ tzproxy ];
  packages = [ nixfmt utop ocamlformat ocaml findlib dune odoc ocaml-lsp ];
}
