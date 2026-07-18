# Constructor for a host: wires the flake specialArg and evaluates the
# module list with nixpkgs' nixosSystem. Hosts call this from their
# default.nix and never touch specialArgs themselves.
{ flake, system, modules }:

flake.inputs.nixpkgs.lib.nixosSystem {
  inherit system modules;
  specialArgs = { inherit flake; };
}
