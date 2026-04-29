{ lib }:

let
  # Stubs for the NixOS options that persistence.nix consumes. We
  # evaluate the module via lib.evalModules instead of pulling in the
  # full NixOS module set, so any option referenced in persistence.nix
  # must be declared here.
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
      systemd.tmpfiles.rules = mkOption {
        type = types.listOf types.str;
        default = [];
      };
      fileSystems = mkOption {
        type = types.attrsOf types.unspecified;
        default = {};
      };
      boot.initrd.systemd.enable = mkOption {
        type = types.bool;
        default = false;
      };
    };
  };

  eval = userCfg: (lib.evalModules {
    modules = [
      ../nixos/modules/environment/persistence.nix
      stubs
      userCfg
    ];
  }).config;

  failing_assertions = cfg: lib.filter (a: !a.assertion) cfg.assertions;
in
{
  test_disabled_by_default = {
    expr = (eval {}).environment.persistence.enable;
    expected = false;
  };

  test_disabled_module_emits_no_tmpfiles_rules = {
    expr = (eval {
      environment.persistence.paths = [ "/etc/ssh" ];
    }).systemd.tmpfiles.rules;
    expected = [];
  };

  test_enabled_without_paths_emits_only_state_dir_rule = {
    expr = (eval {
      environment.persistence.enable = true;
      boot.initrd.systemd.enable = true;
    }).systemd.tmpfiles.rules;
    expected = [ "d /var/state 0755 root root -" ];
  };

  test_each_path_produces_one_tmpfiles_rule = {
    expr = (eval {
      environment.persistence.enable = true;
      environment.persistence.paths = [ "/etc/ssh" "/var/lib/bluetooth" ];
      boot.initrd.systemd.enable = true;
    }).systemd.tmpfiles.rules;
    expected = [
      "d /var/state 0755 root root -"
      "d /var/state/etc/ssh 0755 root root -"
      "d /var/state/var/lib/bluetooth 0755 root root -"
    ];
  };

  test_duplicate_paths_are_deduplicated = {
    expr = (eval {
      environment.persistence.enable = true;
      environment.persistence.paths = [ "/etc/ssh" "/etc/ssh" ];
      boot.initrd.systemd.enable = true;
    }).systemd.tmpfiles.rules;
    expected = [
      "d /var/state 0755 root root -"
      "d /var/state/etc/ssh 0755 root root -"
    ];
  };

  test_each_path_produces_a_bind_mount = {
    expr = (eval {
      environment.persistence.enable = true;
      environment.persistence.paths = [ "/etc/ssh" ];
      boot.initrd.systemd.enable = true;
    }).fileSystems."/etc/ssh";
    expected = {
      device = "/var/state/etc/ssh";
      fsType = "none";
      options = [ "bind" ];
      neededForBoot = true;
    };
  };

  test_state_dir_itself_is_needed_for_boot = {
    expr = (eval {
      environment.persistence.enable = true;
      boot.initrd.systemd.enable = true;
    }).fileSystems."/var/state".neededForBoot;
    expected = true;
  };

  test_custom_state_dir_is_honoured = {
    expr = (eval {
      environment.persistence.enable = true;
      environment.persistence.stateDir = "/persist";
      environment.persistence.paths = [ "/etc/ssh" ];
      boot.initrd.systemd.enable = true;
    }).systemd.tmpfiles.rules;
    expected = [
      "d /persist 0755 root root -"
      "d /persist/etc/ssh 0755 root root -"
    ];
  };

  test_assertion_fires_when_initrd_systemd_disabled = {
    expr = builtins.length (failing_assertions (eval {
      environment.persistence.enable = true;
    }));
    expected = 1;
  };

  test_assertion_fires_for_relative_path = {
    expr = builtins.length (failing_assertions (eval {
      environment.persistence.enable = true;
      environment.persistence.paths = [ "etc/ssh" ];
      boot.initrd.systemd.enable = true;
    }));
    expected = 1;
  };

  test_no_assertions_fire_for_valid_config = {
    expr = failing_assertions (eval {
      environment.persistence.enable = true;
      environment.persistence.paths = [ "/etc/ssh" ];
      boot.initrd.systemd.enable = true;
    });
    expected = [];
  };
}
