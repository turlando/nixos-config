{ config, ... }:
{
  system.stateVersion = "26.05";

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

  networking.hostName = "antigone";
  networking.hostId = "4d86c32a";

  # Import the storage pool at boot and unlock it from its agenix keyfile.
  # Activation (so agenix) runs in the initrd, so /run/agenix already holds
  # the passphrase when the stage-2 import service reads it via keylocation.
  boot.zfs.extraPools = [ config.disko.devices.zpool.storage.name ];

  environment.persistence.enable = true;
  services.ephemeral.enable = true;
  services.ephemeral.datasets."antigone/nixos/ROOT".enable = true;

  users.users = {
    root = {
      hashedPasswordFile = config.age.secrets.user-password-antigone-root.path;
      openssh.authorizedKeys.keys = [ config.environment.ssh.publicKeys.antigone-root_medea-tancredi ];
    };

    # Curates the music library via beets; storage-music grants write to the
    # FLAC/MP3 datasets, wheel is for admin.
    tancredi = {
      uid = 1000;
      description = "Tancredi Orlando";
      isNormalUser = true;
      hashedPasswordFile = config.age.secrets.user-password-antigone-tancredi.path;
      openssh.authorizedKeys.keys = [ config.environment.ssh.publicKeys.antigone-tancredi_medea-tancredi ];
      extraGroups = [
        config.users.groups.wheel.name
        config.users.groups.storage-music.name
      ];
    };
  };
}
