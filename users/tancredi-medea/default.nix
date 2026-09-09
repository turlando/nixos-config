flake:

flake.lib.mkHomeConfiguration {
  inherit flake;
  host = "medea";

  # Declaring MCP servers makes the claude-code module re-wrap the CLI with
  # the stable symlinkJoin, inheriting claude-code's unfree meta, so the name
  # has to be allowed in this set too and not just in the unstable one the
  # package itself comes from. See the claude-code profile and ./claude.
  allowUnfree = [ "claude-code" ];

  modules = [
    flake.inputs.agenix.homeManagerModules.default

    flake.homeManagerModules.modules.default

    flake.homeManagerModules.profiles.base
    flake.homeManagerModules.profiles.age
    flake.homeManagerModules.profiles.claude-code
    flake.homeManagerModules.profiles.emacs
    flake.homeManagerModules.profiles.graphical
    flake.homeManagerModules.profiles.libvirt

    ./claude
    ./configuration.nix
  ];
}
