{ config, ... }:

{
  networking.hostName = "antigone";
  networking.hostId = "4d86c32a"; # Required by ZFS

  networking.interfaces.eth0 = {
    macAddress = "f4:6d:04:7b:d3:0e";
    useDHCP = true;
  };

  networking.firewall.interfaces.eth0.allowedUDPPorts = [
    config.networking.wireguard.interfaces.wg0.listenPort
  ];

  networking.wireguard = {
    enable = true;
    interfaces.wg0 = {
      listenPort = 51820;
      privateKeyFile = "${config.environment.state}/etc/wireguard/antigone-private";
      ips = [ "10.23.42.1/24" ];
      peers = [
        {
          name = "ifigenia";
          publicKey = "CIZPHVl64UixWEAqtSQ9KW4yBCTbWAo4hFQj92lk4W8=";
          allowedIPs = [ "10.23.42.2/32" ];
        }
        {
          name = "smartphone";
          publicKey = "nRIKH8n2U0F8ipN//XhBzcnI41UsTx849MkdA0TXQUI=";
          allowedIPs = [ "10.23.42.3/32" ];
        }
      ];
    };
  };

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
  };
}
