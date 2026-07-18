flake:

flake.lib.mkHomeConfiguration {
  inherit flake;
  host = "antigone";

  # Headless curation home: no graphical profiles, just the beets library
  # module (./beets) on top of the base and agenix profiles.
  modules = [
    flake.inputs.agenix.homeManagerModules.default

    flake.homeManagerModules.modules.default

    flake.homeManagerModules.profiles.base
    flake.homeManagerModules.profiles.age

    ./beets
    ./configuration.nix
  ];
}
