{ config, ... }:
{
  # WireGuard hub. creusa has a stable public IP, so the spokes dial in here:
  # antigone (home, behind a rotating WAN) and roaming clients like medea.
  # creusa forwards between them, so a roaming client reaches antigone's LAN
  # through the tunnel without antigone needing a fixed, reachable endpoint.
  networking.wireguard.interfaces.wg0 = {
    ips = [ "10.241.46.1/24" ];
    listenPort = 51820;
    privateKeyFile = config.age.secrets.wireguard-creusa-key.path;

    peers = [
      # antigone: its tunnel address plus the apartment LAN behind it, so
      # traffic for 10.241.23.0/24 routes here and on to antigone. No endpoint:
      # antigone dials in and creusa learns its address from the handshake.
      {
        publicKey = config.environment.wireguardDevices.antigone.publicKey;
        allowedIPs = [ "10.241.46.2/32" "10.241.23.0/24" ];
      }
      # medea: a single roaming client.
      {
        publicKey = config.environment.wireguardDevices.medea.publicKey;
        allowedIPs = [ "10.241.46.10/32" ];
      }
    ];
  };

  # Forward between peers on the tunnel (roaming client <-> antigone's LAN).
  # The nftables firewall keeps the forward chain default-deny (filterForward),
  # so only tunnel-to-tunnel traffic is allowed and conntrack accepts the
  # return path. The public link cannot forward, so creusa is no open relay.
  boot.kernel.sysctl."net.ipv4.ip_forward" = true;
  networking.nftables.enable = true;
  networking.firewall.filterForward = true;
  networking.firewall.extraForwardRules = ''
    iifname "wg0" oifname "wg0" accept
  '';

  # Accept the tunnel handshake on the public link, and trust peers to reach
  # creusa's own services (e.g. actual-budget) over wg0.
  networking.firewall.interfaces.eth0.allowedUDPPorts = [ 51820 ];
  networking.firewall.trustedInterfaces = [ "wg0" ];
}
