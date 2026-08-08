{ lib }:

let
  # Stubs for the home-manager options that firefox.nix consumes. We
  # evaluate the module via lib.evalModules instead of pulling in the
  # full home-manager module set, so any option referenced in
  # firefox.nix must be declared here.
  stubs = { lib, ... }: {
    options.programs.firefox = with lib; {
      policies = mkOption {
        type = types.attrsOf types.anything;
        default = {};
      };

      profiles = mkOption {
        type = types.attrsOf (types.submodule {
          options.settings = mkOption {
            type = types.attrsOf types.anything;
            default = {};
          };
        });
        default = {};
      };
    };
  };

  fakeOpensc = {
    type = "derivation";
    name = "fake-opensc";
    outPath = "/nix/store/00000000000000000000000000000000-fake-opensc";
  };

  eval = userCfg: (lib.evalModules {
    modules = [
      ../../home-manager/modules/programs/firefox.nix
      stubs
      userCfg
    ];
    specialArgs.pkgs = { opensc = fakeOpensc; };
  }).config;

  securityDevices = (eval {
    programs.firefox.enableSmartCardSupport = true;
  }).programs.firefox.policies.SecurityDevices;
in
{
  test_smart_card_support_off_sets_no_policies = {
    expr = (eval {}).programs.firefox.policies;
    expected = {};
  };

  test_smart_card_support_adds_opensc_module = {
    expr = securityDevices.Add;
    expected = {
      "OpenSC PKCS#11" =
        "${fakeOpensc.outPath}/lib/opensc-pkcs11.so";
    };
  };

  # Firefox matches installed devices by library path, so an Add alone is
  # ignored once the recorded store path is collected. The stale device has
  # to be deleted in the same pass for the profile to converge.
  test_smart_card_support_deletes_stale_device = {
    expr = securityDevices.Delete;
    expected = [ "OpenSC PKCS#11" ];
  };

  test_profile_without_custom_defaults_sets_no_settings = {
    expr = (eval {
      programs.firefox.profiles.tancredi = {};
    }).programs.firefox.profiles.tancredi.settings;
    expected = {};
  };

  test_profile_with_custom_defaults_sets_settings = {
    expr = (eval {
      programs.firefox.profiles.tancredi.enableCustomDefaults = true;
    }).programs.firefox.profiles.tancredi.settings;
    expected = {
      "extensions.pocket.enabled" = false;
      "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
      "widget.use-xdg-desktop-portal.file-picker" = 1;
    };
  };
}
