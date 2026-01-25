{
  base = import ./base.nix;
  clamav = import ./clamav.nix;
  graphical = import ./graphical.nix;
  libvirt = import ./libvirt.nix;
  zfs = import ./zfs.nix;
}
