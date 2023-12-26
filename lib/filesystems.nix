lib:

{
  bootFileSystem = index: partition: {
    "/boot/${toString index}" = {
      device = toString partition;
      fsType = "ext4";
      options = [ "nofail" ];
    };
  };
}
