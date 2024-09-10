{ self, config, pkgs, ... }:

let
  statePath = config.storage.zpools.system.datasets."state".mountPoint;
  notifyPkg = self.packages.x86_64-linux.telegram-send;
  notifyCmd = "${notifyPkg}/bin/telegram-send";
  notifyCfg = "${statePath}/etc/telegram-send.ini";

  notify = from: subject: message:
    pkgs.writeShellScript "notify.sh" ''
      set -e
      echo "${message}" | ${notifyCmd} -c ${notifyCfg} -r "${from}" -s "${subject}"
    '';

  smartdNotify = notify
    "SMART"
    "SMART error ($SMARTD_FAILTYPE) detected"
    ''
      The following warning/error was logged by the smartd daemon:
      $SMARTD_MESSAGE

      Device info:
      $SMARTD_DEVICEINFO
    '';

  upsOnBatteryNotify = notify
    "UPS"
    "Detected power interruption"
    "A power interruption has been detected. Running on batteries.";

  upsOffBatteryNotify = notify
    "UPS"
    "Power restored"
    "The power interruption is over. Running on mains.";

in
{
  services.zfs.zed.settings = {
    ZED_EMAIL_ADDR = [ "root" ];
    ZED_EMAIL_PROG = notifyCmd;
    ZED_EMAIL_OPTS = "-c ${notifyCfg} -r ZFS -s '@SUBJECT@'";
    ZED_NOTIFY_VERBOSE = true;
  };

  services.smartd = {
    enable = true;
    extraOptions = [ "-w ${smartdNotify.outPath}" ];
  };

  services.apcupsd = {
    enable = true;
    hooks = {
      onbattery = upsOnBatteryNotify.outPath;
      offbattery = upsOffBatteryNotify.outPath;
    };
  };
}
