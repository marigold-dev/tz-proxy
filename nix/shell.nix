{ pkgs, tzproxy }:

with pkgs;
with ocamlPackages;
mkShell {
  inputsFrom = [ tzproxy ];
  packages = [ nixfmt ocamlformat ocaml findlib dune odoc ocaml-lsp ];
}
