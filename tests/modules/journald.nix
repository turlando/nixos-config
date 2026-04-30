{ lib }:

let
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
      services.journald.extraConfig = mkOption {
        type = types.lines;
        default = "";
      };
      environment.etc = mkOption {
        type = types.attrsOf (types.submodule {
          options = {
            text   = mkOption { type = types.nullOr types.str; default = null; };
            enable = mkOption { type = types.bool; default = true; };
          };
        });
        default = {};
      };
    };
  };

  eval = userCfg: (lib.evalModules {
    modules = [
      ../../nixos/modules/services/journald.nix
      stubs
      userCfg
    ];
  }).config;

  failing_assertions = cfg: lib.filter (a: !a.assertion) cfg.assertions;

  dropInPath = "systemd/journald.conf.d/99-settings.conf";
in
{
  test_no_drop_in_when_no_settings = {
    expr = builtins.hasAttr dropInPath (eval {}).environment.etc;
    expected = false;
  };

  test_drop_in_emitted_for_one_setting = {
    expr = (eval {
      services.journald.settings.SystemMaxUse = "100M";
    }).environment.etc.${dropInPath}.text;
    expected = ''
      [Journal]
      SystemMaxUse=100M
    '';
  };

  test_null_settings_omitted_from_drop_in = {
    # Setting only some values produces only those keys, sorted by key name.
    expr = (eval {
      services.journald.settings.SystemMaxUse = "100M";
      services.journald.settings.MaxRetentionSec = "1month";
    }).environment.etc.${dropInPath}.text;
    expected = ''
      [Journal]
      MaxRetentionSec=1month
      SystemMaxUse=100M
    '';
  };

  test_assertion_fires_for_extraConfig_collision = {
    expr = builtins.length (failing_assertions (eval {
      services.journald.settings.SystemMaxUse = "100M";
      services.journald.extraConfig = "SystemMaxUse=200M\n";
    }));
    expected = 1;
  };

  test_no_assertion_when_extraConfig_unrelated = {
    expr = failing_assertions (eval {
      services.journald.settings.SystemMaxUse = "100M";
      services.journald.extraConfig = "Storage=persistent\n";
    });
    expected = [];
  };
}
