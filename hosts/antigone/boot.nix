{ config, lib, ... }:

let
  inherit (lib.files) readSshKey;
in
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

  boot.initrd.kernelModules = [ "r8169" ];

  boot.initrd.network.enable = true;

  boot.initrd.network.ssh = let
    stateDir = config.boot.ephemeral.stateDir;
    hostKeys = [
      (stateDir + "/etc/ssh-initrd/ssh_host_rsa_key")
      (stateDir + "/etc/ssh-initrd/ssh_host_ed25519_key")
    ];
    authorizedKeys = [ (readSshKey "boot") ];
  in {
    enable = true;
    port = 2222;
    hostKeys = hostKeys;
    authorizedKeys = authorizedKeys;
  };
}
