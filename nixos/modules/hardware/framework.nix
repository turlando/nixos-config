{ config, lib, pkgs, ... }:

let
  inherit (lib) mkEnableOption mkIf mkOption optional optionalString types;

  cfg = config.hardware.framework;

  tool = "${cfg.package}/bin/framework_tool --driver portio";

  # SoC threshold is appended to charge-current-limit and charge-rate-limit
  # commands when set; pulled out here to avoid duplicating it on each.
  socSuffix = optionalString (cfg.chargingLimitSoc != null)
    " ${toString cfg.chargingLimitSoc}";

  # Each setting is a separate invocation.
  commands = lib.flatten [
    (optional (cfg.chargeLimit        != null) "${tool} --charge-limit ${toString cfg.chargeLimit}")
    (optional (cfg.chargeCurrentLimit != null) "${tool} --charge-current-limit ${toString cfg.chargeCurrentLimit}${socSuffix}")
    (optional (cfg.chargeRateLimit    != null) "${tool} --charge-rate-limit ${toString cfg.chargeRateLimit}${socSuffix}")
  ];
in
{
  options.hardware.framework = {
    enable = mkEnableOption ''
      Framework laptop EC settings management.

      Applies hardware settings at every boot via a systemd oneshot service,
      because the Framework EC does not persist them across power cycles.
    '';

    package = mkOption {
      type = types.package;
      default = pkgs.framework-tool;
      description = "The framework_tool package to use.";
    };

    chargeLimit = mkOption {
      type = types.nullOr (types.ints.between 1 100);
      default = null;
      example = 80;
      description = ''
        Maximum battery charge percentage (1–100). The EC stops charging when
        the battery reaches this level.

        Setting this to 80 is recommended when the laptop is frequently plugged
        in, as it significantly extends battery lifespan.
      '';
    };

    chargeCurrentLimit = mkOption {
      type = types.nullOr types.ints.positive;
      default = null;
      example = 2000;
      description = ''
        Maximum charging current in milliamps. The EC will not exceed this
        current when charging the battery.

        Mutually exclusive with chargeRateLimit.
      '';
    };

    chargeRateLimit = mkOption {
      type = types.nullOr types.numbers.positive;
      default = null;
      example = 0.8;
      description = ''
        Maximum charging rate as a C-rate multiplier of the battery's design
        capacity. For example, 0.5 means the battery charges at half its design
        capacity per hour (~30 W on a 61 Wh pack), while 1.0 means full rate.

        Mutually exclusive with chargeCurrentLimit.
      '';
    };

    chargingLimitSoc = mkOption {
      type = types.nullOr (types.ints.between 0 100);
      default = null;
      example = 50;
      description = ''
        Battery state-of-charge percentage above which the current/rate limit
        takes effect. Below this threshold the battery charges at full speed.

        Requires either chargeCurrentLimit or chargeRateLimit to be set.
      '';
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = commands != [ ];
        message = ''
          hardware.framework is enabled but no settings are configured.
          Set at least one option (e.g. hardware.framework.chargeLimit).
        '';
      }
      {
        assertion = !(cfg.chargeCurrentLimit != null && cfg.chargeRateLimit != null);
        message = ''
          hardware.framework.chargeCurrentLimit and
          hardware.framework.chargeRateLimit are mutually exclusive.
        '';
      }
      {
        assertion = cfg.chargingLimitSoc == null
          || cfg.chargeCurrentLimit != null
          || cfg.chargeRateLimit != null;
        message = ''
          hardware.framework.chargingLimitSoc requires either
          chargeCurrentLimit or chargeRateLimit to be set.
        '';
      }
    ];

    systemd.services.framework-tool-settings = {
      description = "Apply Framework laptop EC settings";
      wantedBy = [ "multi-user.target" ];
      after = [ "systemd-modules-load.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = commands;
      };
    };
  };
}
