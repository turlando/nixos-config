{ config, lib, ... }:
let
  inherit (lib) mkOption types mkIf;
  cfg = config.programs.mozilla-settings;
in {
  options.programs.mozilla-settings = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable default browser settings";
    };
    
    firefox = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "Firefox profiles to apply default settings to";
    };
    
    thunderbird = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "Thunderbird profiles to apply default settings to";
    };
  };

  config = mkIf cfg.enable {
    programs.firefox.profiles = lib.listToAttrs (map (name: {
      name = name;
      value.settings = {
        "extensions.pocket.enabled" = false;
        "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
        "widget.use-xdg-desktop-portal.file-picker" = 1;
      };
    }) cfg.firefox);
    
    programs.thunderbird.profiles = lib.listToAttrs (map (name: {
      name = name;
      value.settings = {
        "widget.use-xdg-desktop-portal.file-picker" = 1;
      };
    }) cfg.thunderbird);
  };
}
