{ flake, system, ... }:

flake.inputs.terranix.lib.terranixConfiguration {
  inherit system;
  modules = [
    ./configuration.nix
  ];
}
