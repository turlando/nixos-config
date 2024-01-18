{ ... }:

{
  boot.drives = [ /dev/disk/by-id/ata-CT500MX500SSD1_1944E225D422 ];
  boot.partitions = [ /dev/disk/by-partlabel/efi ];

  boot.loader.grub = {
    enable = true;
    zfsSupport = true;
    efiSupport = true;
    efiInstallAsRemovable = true;
    device = "nodev";
  };

  boot.initrd.systemd.enable = true;

  boot.ephemeral = {
    enable = true;
    dataset = "system/root@empty";
  };

  boot.supportedFilesystems = [ "ntfs" ];
}
