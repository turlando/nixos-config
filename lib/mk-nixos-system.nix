# Constructor for a host: wires the flake specialArg and evaluates the
# module list with nixpkgs' nixosSystem. Hosts call this from their
# default.nix and never touch specialArgs themselves.
{ flake, system, modules }:

flake.inputs.nixpkgs.lib.nixosSystem {
  inherit system modules;

  specialArgs = {
    inherit flake;
    # Transitional args; consumers still on the old names.
    self = flake;
    lib-age = flake.lib.age;
    nixvirt-lib = flake.inputs.nixvirt.lib;
    pkgs-unstable = import flake.inputs.nixpkgs-unstable { inherit system; };
  };
}
