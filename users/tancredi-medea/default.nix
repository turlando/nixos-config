{ self, agenix, home-manager, nixpkgs, ... }:

home-manager.lib.homeManagerConfiguration {
  pkgs = import nixpkgs {
    system = "x86_64-linux";
  };

  modules = [
    self.homeManagerModules.modules.programs.mozilla-settings
    self.homeManagerModules.modules.programs.ssh

    (self.homeManagerModules.secrets { inherit agenix; })

    self.homeManagerModules.profiles.base
    self.homeManagerModules.profiles.emacs
    self.homeManagerModules.profiles.graphical
    self.homeManagerModules.profiles.libvirt

    ./configuration.nix
  ];
}
