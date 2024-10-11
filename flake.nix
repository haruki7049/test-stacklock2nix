{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    stacklock2nix.url = "github:cdepillabout/stacklock2nix";
    flake-parts.url = "github:hercules-ci/flake-parts";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    systems.url = "github:nix-systems/default";
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = import inputs.systems;

      imports = [
        inputs.treefmt-nix.flakeModule
      ];

      perSystem =
        { pkgs, system, ... }:
        let
          overlays = [
            inputs.stacklock2nix.overlay
          ];

          stacklock = pkgs.stacklock2nix {
            stackYaml = ./stack.yaml;
          };
          haskell-pkg-set = pkgs.haskell.packages.ghcHEAD.override (oldAttrs: {
            inherit (stacklock) all-cabal-hashes;

            overrides = pkgs.lib.composeManyExtensions [
              stacklock.stackYamlResolverOverlay
              stacklock.stackYamlExtraDepsOverlay
              stacklock.stackYamlLocalPkgsOverlay
              stacklock.suggestedOverlay
            ];
          });
          test-stacklock2nix = haskell-pkg-set.test-stacklock2nix;
        in
        {
          treefmt = {
            projectRootFile = "flake.nix";
            programs.nixfmt.enable = true;
            programs.yamlfmt.enable = true;
            programs.ormolu.enable = true;
          };

          _module.args = import inputs.nixpkgs {
            inherit system overlays;
          };

          packages = {
            inherit test-stacklock2nix;
            default = test-stacklock2nix;
          };

          devShells.default = pkgs.mkShell {
            packages = [
              pkgs.stack
              pkgs.cabal-install
              pkgs.ghc
              pkgs.haskell-language-server
              pkgs.nil
            ];
          };
        };
    };
}
