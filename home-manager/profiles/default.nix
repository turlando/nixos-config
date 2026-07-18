# Profiles, exported as file paths so the module system can identify and
# deduplicate each one by file. Importing a profile activates it.
{
  age = ./age.nix;
  base = ./base.nix;
  emacs = ./emacs;
  graphical = ./graphical.nix;
  libvirt = ./libvirt.nix;
}
