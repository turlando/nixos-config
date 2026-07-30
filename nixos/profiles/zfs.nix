{ pkgs, ... }:
{
  # `boot.kernelPackages` is left at its default, the newest LTS. Mainline
  # kernels are removed from nixpkgs once they reach EOL upstream, which
  # usually happens before OpenZFS certifies their successor, so pinning one
  # breaks the build every cycle.
  #
  # `boot.zfs.package` defaults to `pkgs.zfs`, currently the same 2.4 series.
  # Pinning it keeps a new ZFS series from arriving unattended, and fails the
  # build loudly rather than silently downgrading if the series is dropped.
  boot.zfs.package = pkgs.zfs_2_4;

  # `boot.zfs.forceImportRoot` is `true` by default as of NixOS 26.05. Starting
  # from NixOS 26.11 the new default will be `false`. It is highly recommended
  # to set it to `false` to reduce the risk of data loss.
  boot.zfs.forceImportRoot = false;

  # Scrubbing is off by default and enabled here. Periodic TRIM needs no line:
  # `services.zfs.trim.enable` already defaults to `true`.
  services.zfs.autoScrub.enable = true;
}
