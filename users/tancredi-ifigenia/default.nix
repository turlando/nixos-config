{ self, lib, nixpkgs, flake-utils, home-manager, ... }@args:

home-manager.lib.homeManagerConfiguration {
  pkgs = nixpkgs.legacyPackages.${flake-utils.lib.system.x86_64-linux};
  extraSpecialArgs = {
    lib = lib.extend (_: _: home-manager.lib);
  };
  modules = [
    {
      home.stateVersion = "24.11";
      home.username = "tancredi";
      home.homeDirectory = "/home/tancredi";
    }
    self.homeManagerModules.defaults
    ./configuration.nix
  ];
}
