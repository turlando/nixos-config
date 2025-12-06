{ lib, pkgs, config, ... }:

let
  inherit (lib) mkEnableOption mkIf mkOption types;
  inherit (lib.strings) concatStringsSep;

  cfg = config.security.run0;
  mkGroupJS = g: ''subject.isInGroup("${g}")'';
  groupExpr = concatStringsSep " || " (map mkGroupJS cfg.allowedGroups);
in
{
  options.security.run0 = {
    enable = mkEnableOption "run0 with Polkit AUTH_KEEP";

    package = mkOption {
      type = types.package;
      default = pkgs.systemd; # provides run0 (systemd ≥ 256)
      description = "Package providing the run0 binary.";
    };

    allowedGroups = mkOption {
      type = types.listOf types.str;
      default = [ "wheel" ];
      example = [ "wheel" "admins" ];
      description = ''
        Unix groups whose members may elevate with run0 and have their
        authentication cached (AUTH_KEEP).
      '';
    };
  };

  config = mkIf cfg.enable {
    assertions = [{
      assertion = config.security.polkit.enable;
      message = "security.run0 requires security.polkit.enable = true.";
    }];

    environment.systemPackages = [ cfg.package ];

    security.polkit.extraConfig = ''
      polkit.addRule(function (action, subject) {
        if (action.id == "org.freedesktop.systemd1.run" && (${groupExpr})) {
          return polkit.Result.AUTH_KEEP;
        }
      });
    '';
  };
}
