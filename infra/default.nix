{ system, terranix, ... }:

terranix.lib.terranixConfiguration {
  inherit system;
  modules = [
    ./configuration.nix
  ];
}
