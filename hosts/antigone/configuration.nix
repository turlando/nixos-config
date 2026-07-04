{ config, ... }:
{
  system.stateVersion = "26.05";

  networking.hostName = "antigone";
  networking.hostId = "4d86c32a";

  environment.persistence.enable = true;
  services.ephemeral.enable = true;
  services.ephemeral.datasets."antigone/nixos/ROOT".enable = true;

  services.journald.settings = {
    SystemMaxUse = "256M";
    SystemMaxFileSize = "32M";
    MaxRetentionSec = "1month";
  };

  # Redundant boot: GRUB EFI is installed to both ESPs so the machine boots
  # from whichever disk survives; the mount points come from disko, where
  # both ESPs are mounted nofail. `devices = ["nodev"]` keeps each entry
  # EFI-only, so grub-install skips the BIOS/i386-pc step. With no top-level
  # `device` (boot-grub profile) the grub module injects no phantom `/boot`
  # entry, so this list stands as-is.
  boot.loader.grub.mirroredBoots = let
    inherit (config.disko.devices.disk) antigone-1 antigone-2;
    boot1 = antigone-1.content.partitions.ESP.content.mountpoint;
    boot2 = antigone-2.content.partitions.ESP.content.mountpoint;
  in [
    { path = boot1; efiSysMountPoint = boot1; devices = [ "nodev" ]; }
    { path = boot2; efiSysMountPoint = boot2; devices = [ "nodev" ]; }
  ];

  users.users.root = {
    hashedPasswordFile = config.age.secrets.user-password-antigone-root.path;
    openssh.authorizedKeys.keys = [ config.environment.sshPublicKeys.antigone-root_medea-tancredi ];
  };
}
