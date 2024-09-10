{ pkgs ? import <nixpkgs> {}, ... }:

pkgs.mkShell {
  buildInputs = with pkgs; [ gnumake home-manager ];
  NIX_CONFIG = "experimental-features = nix-command flakes repl-flake";
}
