{
  pkgs ? import <nixpkgs> { },
}:

pkgs.mkShell {
  packages = [
    pkgs.stack
    pkgs.haskell-language-server
    pkgs.haskell.packages.ghc982.ghc
    pkgs.nil
  ];
}
