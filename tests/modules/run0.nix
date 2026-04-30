{ lib }:

let
  fakePackage = {
    type = "derivation";
    outPath = "/nix/store/0000000000000000000000000000000-systemd";
    name = "systemd";
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
      environment.systemPackages = mkOption {
        type = types.listOf types.package;
        default = [];
      };
      security.polkit.enable = mkOption {
        type = types.bool;
        default = false;
      };
      security.polkit.extraConfig = mkOption {
        type = types.lines;
        default = "";
      };
    };
  };

  eval = userCfg: (lib.evalModules {
    modules = [
      ../../nixos/modules/security/run0.nix
      stubs
      { _module.args.pkgs = { systemd = fakePackage; }; }
      userCfg
    ];
  }).config;

  failing_assertions = cfg: lib.filter (a: !a.assertion) cfg.assertions;
in
{
  test_disabled_by_default = {
    expr = (eval {}).security.run0.enable;
    expected = false;
  };

  test_default_allowed_groups_is_wheel = {
    expr = (eval {}).security.run0.allowedGroups;
    expected = [ "wheel" ];
  };

  test_polkit_rule_contains_default_group = {
    expr = lib.hasInfix ''subject.isInGroup("wheel")'' (eval {
      security.run0.enable = true;
      security.polkit.enable = true;
    }).security.polkit.extraConfig;
    expected = true;
  };

  test_polkit_rule_joins_multiple_groups_with_or = {
    expr = let
      cfg = (eval {
        security.run0.enable = true;
        security.run0.allowedGroups = [ "wheel" "admins" ];
        security.polkit.enable = true;
      }).security.polkit.extraConfig;
    in
      lib.hasInfix ''subject.isInGroup("wheel")'' cfg
      && lib.hasInfix ''subject.isInGroup("admins")'' cfg
      && lib.hasInfix " || " cfg;
    expected = true;
  };

  test_assertion_fires_when_polkit_disabled = {
    expr = builtins.length (failing_assertions (eval {
      security.run0.enable = true;
    }));
    expected = 1;
  };

  test_no_assertions_for_valid_config = {
    expr = failing_assertions (eval {
      security.run0.enable = true;
      security.polkit.enable = true;
    });
    expected = [];
  };

  test_disabled_module_emits_no_polkit_rule = {
    expr = (eval {}).security.polkit.extraConfig;
    expected = "";
  };
}
