lib:

{
  # type: int -> str -> AttrSet
  bootFileSystem = index: partition: {
    "/boot/${toString index}" = {
      device = toString partition;
      fsType = "ext4";
      options = [ "nofail" ];
    };
  };

  # type: str -> str -> str -> AttrSet
  zfsFileSystem = pool: filesystem: mountPoint: {
    "${mountPoint}" = {
      device = "${pool}/${filesystem}";
      fsType = "zfs";
    };
  };
}
