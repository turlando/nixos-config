{ config, flake, lib, pkgs, ... }:

let
  inherit (lib) mkOption types;

  cfg = config.nixpkgs.unstable;
in {
  options.nixpkgs.unstable = {
    allowUnfree = mkOption {
      type = types.listOf types.str;
      default = [];
      example = [ "claude-code" ];
      description = ''
        Names (per lib.getName) of unfree packages allowed in the
        unstable set.
      '';
    };

    pkgs = mkOption {
      type = types.pkgs;
      readOnly = true;
      default = import flake.inputs.nixpkgs-unstable {
        inherit (pkgs.stdenv.hostPlatform) system;
        config.allowUnfreePredicate = pkg:
          builtins.elem (lib.getName pkg) cfg.allowUnfree;
      };
      defaultText = "nixpkgs-unstable instantiated for this configuration's platform";
      description = ''
        The nixpkgs-unstable package set, instantiated once per
        configuration. This is the only place the unstable input is
        instantiated; consumers reference packages as
        `config.nixpkgs.unstable.pkgs.<name>`.
      '';
    };
  };
}
