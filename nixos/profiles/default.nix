{
  age = import ./age.nix;
  base = import ./base.nix;
  clamav = import ./clamav.nix;
  graphical = import ./graphical.nix;
  libvirt = import ./libvirt.nix;
  openssh-server = import ./openssh-server.nix;
  zfs = import ./zfs.nix;
}
