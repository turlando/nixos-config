{ self, agenix, home-manager, nixpkgs, nixpkgs-unstable, ... }:

let
  nixosConfiguration = self.nixosConfigurations.medea.config;
  system = nixosConfiguration.nixpkgs.hostPlatform.system;
  allowedUnfree = [ "claude-code" ];
in home-manager.lib.homeManagerConfiguration {
  pkgs = import nixpkgs { inherit system; };

  extraSpecialArgs = {
    lib-age = self.lib.age;
    inherit nixosConfiguration;
    packages = self.packages.${system};
    pkgs-unstable = import nixpkgs-unstable {
      inherit system;
      config.allowUnfreePredicate = pkg:
        builtins.elem (nixpkgs.lib.getName pkg) allowedUnfree;
    };
  };

  modules = [
    agenix.homeManagerModules.default

    self.homeManagerModules.modules.fonts.families
    self.homeManagerModules.modules.programs.firefox
    self.homeManagerModules.modules.programs.thunderbird
    self.homeManagerModules.modules.environment.syncthing-devices

    self.homeManagerModules.profiles.base
    self.homeManagerModules.profiles.age
    self.homeManagerModules.profiles.emacs
    self.homeManagerModules.profiles.graphical
    self.homeManagerModules.profiles.libvirt

    ./claude
    ./configuration.nix
  ];
}
