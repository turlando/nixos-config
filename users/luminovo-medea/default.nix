{ self, agenix, home-manager, nixpkgs, ... }:

home-manager.lib.homeManagerConfiguration {
  pkgs = import nixpkgs {
    system = "x86_64-linux";
  };

  extraSpecialArgs = {
    lib-age = self.lib.age;
    nixosConfiguration = self.nixosConfigurations.medea.config;
  };

  modules = [
    agenix.homeManagerModules.default

    self.homeManagerModules.modules.programs.ssh
    self.homeManagerModules.modules.programs.firefox
    self.homeManagerModules.modules.programs.thunderbird

    self.homeManagerModules.profiles.base
    self.homeManagerModules.profiles.age
    self.homeManagerModules.profiles.emacs
    self.homeManagerModules.profiles.graphical

    ./configuration.nix
  ];
}
