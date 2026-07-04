_:
{
  # Pin interface names by MAC so they stay stable across reboots and as
  # NICs are added.

  # wan0: builtin NIC (e1000e), uplink to the ZTE modem.
  systemd.network.links."10-wan0" = {
    matchConfig.MACAddress = "10:7b:44:49:e6:8a";
    linkConfig.Name = "wan0";
  };

  # lan0: PCIe NIC (r8169), the trusted apartment LAN.
  systemd.network.links."10-lan0" = {
    matchConfig.MACAddress = "c4:e9:84:04:c2:64";
    linkConfig.Name = "lan0";
  };
}
