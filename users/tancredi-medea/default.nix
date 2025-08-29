{ self, agenix, emacs-overlay, home-manager, nixpkgs, ... }:

let
  system = "x86_64-linux";
in home-manager.lib.homeManagerConfiguration {
  pkgs = import nixpkgs {
    inherit system;
    overlays = [
      emacs-overlay.overlays.default
    ];
  };

  modules = [
    agenix.homeManagerModules.default

    self.homeManagerModules.programs.mozilla-settings
    self.homeManagerModules.programs.ssh

    self.homeManagerModules.secrets

    self.homeManagerModules.profiles.base
    self.homeManagerModules.profiles.emacs
    self.homeManagerModules.profiles.graphical

    ./configuration.nix
  ];
}
