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
      boot.initrd.systemd.enable = mkOption {
        type = types.bool;
        default = false;
      };
      boot.initrd.systemd.services = mkOption {
        type = types.attrsOf types.unspecified;
        default = {};
      };
    };
  };

  eval = userCfg: (lib.evalModules {
    modules = [
      ../../nixos/modules/services/ephemeral.nix
      stubs
      userCfg
    ];
  }).config;

  failing_assertions = cfg: lib.filter (a: !a.assertion) cfg.assertions;
in
{
  test_disabled_by_default = {
    expr = (eval {}).services.ephemeral.enable;
    expected = false;
  };

  test_default_snapshot_is_empty = {
    expr = (eval {
      services.ephemeral.datasets."rpool/nixos/root" = {};
    }).services.ephemeral.datasets."rpool/nixos/root".snapshot;
    expected = "empty";
  };

  test_unit_name_escapes_slashes = {
    # Regression test: ZFS dataset names contain slashes, which are not
    # legal in systemd unit names. The module must replace them with
    # dashes (see commit 08ef899).
    expr = lib.attrNames (eval {
      services.ephemeral.enable = true;
      services.ephemeral.datasets."rpool/nixos/root" = { enable = true; };
      boot.initrd.systemd.enable = true;
    }).boot.initrd.systemd.services;
    expected = [ "ephemeral@rpool-nixos-root" ];
  };

  test_service_runs_zfs_rollback_to_snapshot = {
    expr = (eval {
      services.ephemeral.enable = true;
      services.ephemeral.datasets."pool/data" = {
        enable = true;
        snapshot = "blank";
      };
      boot.initrd.systemd.enable = true;
    }).boot.initrd.systemd.services."ephemeral@pool-data".serviceConfig.ExecStart;
    expected = [ "@/bin/zfs zfs rollback -r pool/data@blank" ];
  };

  test_disabled_dataset_emits_no_service = {
    expr = lib.attrNames (eval {
      services.ephemeral.enable = true;
      services.ephemeral.datasets."pool/data" = { enable = false; };
      boot.initrd.systemd.enable = true;
    }).boot.initrd.systemd.services;
    expected = [];
  };

  test_disabled_module_emits_no_service = {
    expr = lib.attrNames (eval {
      services.ephemeral.enable = false;
      services.ephemeral.datasets."pool/data" = { enable = true; };
      boot.initrd.systemd.enable = true;
    }).boot.initrd.systemd.services;
    expected = [];
  };

  test_assertion_fires_when_initrd_systemd_disabled = {
    expr = builtins.length (failing_assertions (eval {
      services.ephemeral.enable = true;
    }));
    expected = 1;
  };

  test_no_assertions_for_disabled_module = {
    # When ephemeral is disabled, the assertion antecedent is false,
    # so the implication is vacuously true regardless of initrd state.
    expr = failing_assertions (eval {});
    expected = [];
  };
}
