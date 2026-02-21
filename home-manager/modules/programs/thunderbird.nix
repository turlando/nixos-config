{ lib, ... }:
let
  inherit (lib) mkEnableOption mkIf mkOption types;
in {
  options.programs.thunderbird.profiles = mkOption {
    type = types.attrsOf (types.submodule ({ config, ... }: {
      options.enableCustomDefaults =
        mkEnableOption "custom default Thunderbird settings";

      config = mkIf config.enableCustomDefaults {
        settings = {
          "widget.use-xdg-desktop-portal.file-picker" = 1;
        };
      };
    }));
  };
}
