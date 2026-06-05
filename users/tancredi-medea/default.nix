{ self, agenix, home-manager, nixpkgs, ... }:

let
  nixosConfiguration = self.nixosConfigurations.medea.config;
  system = nixosConfiguration.nixpkgs.hostPlatform.system;
in home-manager.lib.homeManagerConfiguration {
  pkgs = import nixpkgs { inherit system; };

  extraSpecialArgs = {
    lib-age = self.lib.age;
    inherit nixosConfiguration;
    packages = self.packages.${system};
  };

  modules = [
    agenix.homeManagerModules.default

    self.homeManagerModules.modules.fonts.families
    self.homeManagerModules.modules.programs.firefox
    self.homeManagerModules.modules.programs.thunderbird

    self.homeManagerModules.profiles.base
    self.homeManagerModules.profiles.age
    self.homeManagerModules.profiles.emacs
    self.homeManagerModules.profiles.graphical
    self.homeManagerModules.profiles.libvirt

    ./configuration.nix
  ];
}
