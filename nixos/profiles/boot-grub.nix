_:
{
  # UEFI GRUB installed to the firmware-hardcoded removable path
  # (EFI/BOOT/BOOT*.EFI) on each ESP, so the machine boots from whichever
  # disk survives without relying on NVRAM entries. `efiInstallAsRemovable`
  # requires `boot.loader.efi.canTouchEfiVariables = false` (base profile);
  # a hard assertion ties the two together.
  #
  # No top-level `device`/`devices`: setting them makes the grub module
  # inject a phantom mirroredBoots entry at `/boot`, which fails where
  # `/boot` is the ZFS root dir rather than a FAT ESP. Hosts list their
  # real ESP mounts in `boot.loader.grub.mirroredBoots`, each with
  # `devices = ["nodev"]` so grub-install skips the BIOS/i386-pc step and
  # does the EFI install only.
  #
  # `copyKernels` keeps kernels/initrds on the FAT ESP so GRUB never has to
  # read the encrypted ZFS pool.
  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    efiInstallAsRemovable = true;
    copyKernels = true;
    configurationLimit = 10;
  };
}
