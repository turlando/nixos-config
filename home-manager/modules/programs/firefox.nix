{ lib, ... }:
let
  inherit (lib) mkEnableOption mkIf mkOption types;
in {
  options.programs.firefox.profiles = mkOption {
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
}
