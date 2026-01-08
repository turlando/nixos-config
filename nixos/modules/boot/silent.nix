{ config, lib, ... }:

let
  inherit (lib) mkIf mkEnableOption;
in {
  options.boot.silent.enable = mkEnableOption ''
    Enable a graphical silent boot.

    This configures the initrd, and adjusts kernel parameters and systemd
    settings so that no verbose boot messages are shown, only the Plymouth
    splash.

    Requires boot.initrd.systemd.enable = true.
  '';

  config = mkIf config.boot.silent.enable {
    boot.loader.timeout = 0;
    boot.initrd.verbose = false;
    boot.consoleLogLevel = 3;
    boot.kernelParams = [
      "quiet"
      "splash"
      "rd.systemd.show_status=auto"
      "rd.udev.log_level=3"
      "vt.global_cursor_default=0"
    ];
  };
}
