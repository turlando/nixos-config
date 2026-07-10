{ self, agenix, home-manager, nixpkgs, ... }:

let
  nixosConfiguration = self.nixosConfigurations.antigone.config;
  system = nixosConfiguration.nixpkgs.hostPlatform.system;
in home-manager.lib.homeManagerConfiguration {
  pkgs = import nixpkgs { inherit system; };

  extraSpecialArgs = {
    lib-age = self.lib.age;
    inherit nixosConfiguration;
    packages = self.packages.${system};
  };

  # Headless curation home: no graphical profiles, just the beets library
  # module (./beets) on top of the base and agenix profiles.
  modules = [
    agenix.homeManagerModules.default

    self.homeManagerModules.profiles.base
    self.homeManagerModules.profiles.age

    ./beets
    ./configuration.nix
  ];
}
