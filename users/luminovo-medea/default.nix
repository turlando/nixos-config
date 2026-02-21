{ self, agenix, home-manager, nixpkgs, ... }:

home-manager.lib.homeManagerConfiguration {
  pkgs = import nixpkgs {
    system = "x86_64-linux";
  };

  modules = [
    agenix.homeManagerModules.default

    self.homeManagerModules.modules.programs.ssh
    self.homeManagerModules.modules.programs.firefox
    self.homeManagerModules.modules.programs.thunderbird

    self.homeManagerModules.secrets

    self.homeManagerModules.profiles.base
    self.homeManagerModules.profiles.emacs
    self.homeManagerModules.profiles.graphical

    ./configuration.nix
  ];
}
