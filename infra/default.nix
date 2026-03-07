{ self, system, terranix, ... }:

terranix.lib.terranixConfiguration  {
  inherit system;
  extraArgs = {
    inherit (self) nixosConfigurations;
  };
  modules = [
    ./configuration.nix
  ];
}
