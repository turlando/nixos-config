{ config, lib, ... }:

{
  boot.loader.grub = {
    enable = true;
    mirroredBoots = [
      {
        devices = [ "/dev/disk/by-id/ata-Lexar_SSD_NS100_512GB_MJ95272016149" ];
        path = "/boot/1";
      }
      {
        devices = [ "/dev/disk/by-id/ata-Lexar_SSD_NS100_512GB_MJ95272016260" ];
        path = "/boot/2";
      }
    ];
  };

  fileSystems = {
    "/boot/1" = {
      device = "/dev/disk/by-partlabel/boot-1";
      fsType = "ext4";
      options = [ "nofail" ];
    };
    "/boot/2" = {
      device = "/dev/disk/by-partlabel/boot-2";
      fsType = "ext4";
      options = [ "nofail" ];
    };
  };

  boot.initrd.kernelModules = [ "r8169" ];
  boot.initrd.network.enable = true;

  boot.initrd.network.ssh = {
    enable = true;
    port = 2222;
    hostKeys = [
      "${config.environment.state}/etc/ssh-initrd/ssh_host_rsa_key"
      "${config.environment.state}/etc/ssh-initrd/ssh_host_ed25519_key"
    ];
    authorizedKeys = [ (lib.files.readSshKey "boot") ];
  };

  services.ephemeral = {
    enable = true;
    datasets = {
      "${config.storage.zpools.system.datasets.root.name}" = { enable = true; };
    };
  };
}
