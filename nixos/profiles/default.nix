# Profiles, exported as file paths so the module system can identify and
# deduplicate each one by file. Importing a profile activates it.
{
  age = ./age.nix;
  base = ./base.nix;
  boot-grub = ./boot-grub.nix;
  boot-systemd = ./boot-systemd.nix;
  clamav = ./clamav.nix;
  graphical = ./graphical.nix;
  initrd-openssh-server = ./initrd-openssh-server.nix;
  libvirt = ./libvirt.nix;
  openssh-server = ./openssh-server.nix;
  smartcard = ./smartcard.nix;
  zfs = ./zfs.nix;
}
