{ ... }:

{
  boot.drives = [
    /dev/disk/by-id/ata-Lexar_SSD_NS100_512GB_MJ95272016149
    /dev/disk/by-id/ata-Lexar_SSD_NS100_512GB_MJ95272016260
  ];

  boot.partitions = [
    /dev/disk/by-partlabel/boot-1
    /dev/disk/by-partlabel/boot-2
  ];

  boot.loader.grub.enable = true;

  boot.ephemeral = {
    enable = true;
    dataset = "system/root@empty";
  };
}
