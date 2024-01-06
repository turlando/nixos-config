{ ... }:

{
  networking.hostName = "ifigenia";
  networking.hostId = "a8c08001"; # Required by ZFS

  networking.interfaces = {
    eth0 = { macAddress = "50:7b:9d:02:13:03"; };
    wlan0 = { macAddress = "4c:34:88:24:ff:13"; };
  };
}
