{ lib }:

let
  # Minimal derivation-shaped stub so types.package accepts our package
  # override without requiring real pkgs.
  fakePackage = {
    type = "derivation";
    outPath = "/nix/store/0000000000000000000000000000000-framework-tool";
    name = "framework-tool";
  };

  stubs = { lib, ... }: {
    options = with lib; {
      assertions = mkOption {
        type = types.listOf (types.submodule {
          options = {
            assertion = mkOption { type = types.bool; };
            message   = mkOption { type = types.str; };
          };
        });
        default = [];
      };
      systemd.services = mkOption {
        type = types.attrsOf types.unspecified;
        default = {};
      };
    };
  };

  eval = userCfg: (lib.evalModules {
    modules = [
      ../../nixos/modules/hardware/framework.nix
      stubs
      { _module.args.pkgs = { framework-tool = fakePackage; }; }
      userCfg
    ];
  }).config;

  failing_assertions = cfg: lib.filter (a: !a.assertion) cfg.assertions;

  execStart = cfg:
    cfg.systemd.services.framework-tool-settings.serviceConfig.ExecStart;
in
{
  test_disabled_by_default = {
    expr = (eval {}).hardware.framework.enable;
    expected = false;
  };

  test_charge_limit_alone_produces_one_command = {
    expr = builtins.length (execStart (eval {
      hardware.framework.enable = true;
      hardware.framework.chargeLimit = 80;
    }));
    expected = 1;
  };

  test_charge_limit_command_contains_value = {
    expr = lib.hasInfix " --charge-limit 80" (builtins.head (execStart (eval {
      hardware.framework.enable = true;
      hardware.framework.chargeLimit = 80;
    })));
    expected = true;
  };

  test_no_soc_suffix_when_soc_unset = {
    # chargeRateLimit alone produces a command with no trailing SoC value.
    expr = lib.hasSuffix " 50" (builtins.head (execStart (eval {
      hardware.framework.enable = true;
      hardware.framework.chargeRateLimit = 0.5;
    })));
    expected = false;
  };

  test_soc_appended_to_charge_rate_limit = {
    # chargeRateLimit + chargingLimitSoc => SoC threshold appended.
    expr = lib.hasSuffix " 50" (builtins.head (execStart (eval {
      hardware.framework.enable = true;
      hardware.framework.chargeRateLimit = 0.5;
      hardware.framework.chargingLimitSoc = 50;
    })));
    expected = true;
  };

  test_assertion_fires_for_no_options = {
    expr = builtins.length (failing_assertions (eval {
      hardware.framework.enable = true;
    }));
    expected = 1;
  };

  test_assertion_fires_for_mutually_exclusive_limits = {
    expr = builtins.length (failing_assertions (eval {
      hardware.framework.enable = true;
      hardware.framework.chargeCurrentLimit = 1500;
      hardware.framework.chargeRateLimit = 0.5;
    }));
    expected = 1;
  };

  test_assertion_fires_for_soc_without_limit = {
    # chargingLimitSoc requires either chargeCurrentLimit or
    # chargeRateLimit; chargeLimit alone does not satisfy it.
    expr = builtins.length (failing_assertions (eval {
      hardware.framework.enable = true;
      hardware.framework.chargeLimit = 80;
      hardware.framework.chargingLimitSoc = 50;
    }));
    expected = 1;
  };

  test_no_assertions_for_valid_config = {
    expr = failing_assertions (eval {
      hardware.framework.enable = true;
      hardware.framework.chargeLimit = 80;
    });
    expected = [];
  };
}
