{
  age = import ./age.nix;
  base = import ./base.nix;
  boot-grub = import ./boot-grub.nix;
  boot-systemd = import ./boot-systemd.nix;
  clamav = import ./clamav.nix;
  graphical = import ./graphical.nix;
  libvirt = import ./libvirt.nix;
  openssh-server = import ./openssh-server.nix;
  smartcard = import ./smartcard.nix;
  zfs = import ./zfs.nix;
}
