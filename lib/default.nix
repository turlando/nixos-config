lib:

{
  attrsets = lib.attrsets // (import ./attrsets.nix lib);
  filesystems = import ./filesystems.nix lib;
  grub = import ./grub.nix lib;
}
