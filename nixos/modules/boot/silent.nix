{ config, lib, ... }:

let
  inherit (lib) mkIf mkEnableOption mkOption types;
in {
  options.boot.silent.enable = mkEnableOption ''
    Enable a graphical silent boot.

    This sets up Plymouth, configures the initrd, and adjusts kernel
    parameters and systemd settings so that no verbose boot messages
    are shown, only the Plymouth splash.

    Requires boot.initrd.systemd.enable = true.
  '';

  config = mkIf config.boot.silent.enable {
    boot.loader.timeout = 0;
    boot.initrd.verbose = false;
    boot.kernelParams = [
      "quiet"
      "splash"
      "rd.systemd.show_status=auto"
      "udev.log_level=3"
      "vt.global_cursor_default=0"
    ];
  };
}
