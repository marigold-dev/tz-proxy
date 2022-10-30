{
  description = "Nix Flake";

  inputs = {
    nixpkgs.url =
      "github:nix-ocaml/nix-overlays/029bcd66be430e4f1d0a73b771780564b4e95aa4";
    flake-utils.url = "github:numtide/flake-utils";
    nix-filter.url = "github:numtide/nix-filter";

    ocaml-overlays.url =
      "github:nix-ocaml/nix-overlays/029bcd66be430e4f1d0a73b771780564b4e95aa4";
    ocaml-overlays.inputs = {
      nixpkgs.follows = "nixpkgs";
      flake-utils.follows = "flake-utils";
    };
  };

  outputs = { self, nixpkgs, ocaml-overlays, nix-filter, flake-utils }:
    let supportedSystems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" ];
    in with flake-utils.lib;
    eachSystem supportedSystems (system:
      let
        pkgs = (ocaml-overlays.makePkgs {
          inherit system;
          extraOverlays = [ (import ./nix/overlay.nix) ];
        }).extend
          (self: super: { ocamlPackages = super.ocaml-ng.ocamlPackages_5_0; });

        pkgs_static = pkgs.pkgsCross.musl64;

        tzproxy_static = pkgs.callPackage ./nix {
          pkgs = pkgs_static;
          doCheck = true;
          static = true;
          inherit nix-filter;
        };

        tzproxy = pkgs.callPackage ./nix {
          doCheck = true;
          inherit nix-filter;
        };
      in {
        devShell = import ./nix/shell.nix { inherit pkgs tzproxy; };
        packages = {
          # inherit tzproxy tzproxy_static;
          # docker = import ./nix/docker.nix {
          #     inherit pkgs;
          #     tzproxy = tzproxy_static;
          #   };

          inherit tzproxy tzproxy_static;
          docker = import ./nix/docker.nix {
            inherit pkgs;
            tzproxy = tzproxy;
          };
        };

        formatter = pkgs.callPackage ./nix/formatter.nix { };
      }) // {
        hydraJobs = {
          x86_64-linux = self.packages.x86_64-linux;
          aarch64-darwin = {
            # darwin doesn't support static builds and docker
            inherit (self.packages.aarch64-darwin) tzproxy;
          };
        };
      };
}
