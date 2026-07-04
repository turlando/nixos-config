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

  # Redundant boot: GRUB EFI installed to both ESPs (/boot/1, /boot/2), so
  # the machine boots from whichever disk survives. Both ESPs are mounted
  # nofail (see disko.nix) so a missing disk never blocks boot.
  #
  # `devices = ["nodev"]` keeps each entry EFI-only, so grub-install skips
  # the BIOS/i386-pc step. With no top-level `device` (boot-grub profile),
  # the grub module injects no phantom `/boot` entry, so this list stands
  # as-is (no mkForce needed).
  boot.loader.grub.mirroredBoots = [
    { path = "/boot/1"; efiSysMountPoint = "/boot/1"; devices = [ "nodev" ]; }
    { path = "/boot/2"; efiSysMountPoint = "/boot/2"; devices = [ "nodev" ]; }
  ];

  users.users.root = {
    hashedPasswordFile = config.age.secrets.user-password-antigone-root.path;
    openssh.authorizedKeys.keys = [ config.environment.sshPublicKeys.antigone-root_medea-tancredi ];
  };
}
