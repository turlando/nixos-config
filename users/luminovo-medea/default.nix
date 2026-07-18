flake:

flake.lib.mkHomeConfiguration {
  inherit flake;
  host = "medea";
  allowUnfree = [ "slack" ];

  modules = [
    flake.inputs.agenix.homeManagerModules.default

    flake.homeManagerModules.modules.default

    flake.homeManagerModules.profiles.base
    flake.homeManagerModules.profiles.age
    flake.homeManagerModules.profiles.emacs
    flake.homeManagerModules.profiles.graphical

    ./configuration.nix
  ];
}
