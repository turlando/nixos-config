{ config, lib, pkgs, ... }:
let
  inherit (lib) mkEnableOption mkIf mkOption types;
  cfg = config.programs.firefox;
in {
  options.programs.firefox = {
    enableSmartCardSupport =
      mkEnableOption "smart card support via OpenSC PKCS#11";

    profiles = mkOption {
      type = types.attrsOf (types.submodule ({ config, ... }: {
        options.enableCustomDefaults =
          mkEnableOption "custom default Firefox settings";

        config = mkIf config.enableCustomDefaults {
          settings = {
            "extensions.pocket.enabled" = false;
            "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
            "widget.use-xdg-desktop-portal.file-picker" = 1;
          };
        };
      }));
    };
  };

  config = mkIf cfg.enableSmartCardSupport {
    # Firefox matches installed devices by library path, so a bare Add leaves a
    # stale entry behind once its store path is garbage collected. Delete runs
    # first in the same pass, reconciling the profile on every startup.
    programs.firefox.policies.SecurityDevices = {
      Delete = [ "OpenSC PKCS#11" ];
      Add."OpenSC PKCS#11" = "${pkgs.opensc}/lib/opensc-pkcs11.so";
    };
  };
}
