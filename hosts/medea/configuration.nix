{ config, ... }:
{
  system.stateVersion = "26.05";

  networking.hostName = "medea";
  networking.hostId = "e8d8a1f8";
  #networking.interfaces.eth0 =  { macAddress = "9c:bf:0d:00:be:a2"; };
  networking.interfaces.wlan0 = { macAddress = "d8:b3:2f:bd:d6:f1"; };

  hardware.framework = {
    enable = true;

    # Keep cell voltage below ~4.1 V (80% SoC) instead of the 4.2 V at 100%.
    chargeLimit = 80;

    # Gentle 0.5 C rate (~1958 mA) reduces charging heat and lithium-plating risk.
    chargeRateLimit = 0.5;

    # Only enforce the rate limit above 50 % SoC, where cell voltage is highest
    # and stress matters most. Below 50% the battery charges at full speed.
    chargingLimitSoc = 50;
  };

  i18n.extra-locale = "it_IT.UTF-8";
  time.timeZone = "Europe/Rome";

  # storage/music is not a home, so nothing chowns its mountpoint; hand it to
  # tancredi (the syncthing user), readable by everyone. It mounts before
  # systemd-tmpfiles-setup, so a tmpfiles rule owns it without a post-mount unit.
  systemd.tmpfiles.rules = let
    musicDir = config.disko.devices.zpool.medea.datasets."storage/music/electronic".mountpoint;
  in [
    "d ${musicDir} 0755 tancredi users -"
  ];

  # WireGuard roaming client, scoped to tancredi and off by default
  # (connect-when-away): bring it up from the NetworkManager applet only when
  # away from the LAN. Split tunnel, so only the internal supernet
  # (10.241.0.0/16) routes through creusa and the rest of the internet stays
  # direct. While connected, dns + the negative dns-priority make antigone the
  # resolver so rhyzomatic.net names resolve over the tunnel. The private key is
  # substituted from its agenix secret at activation, so it never enters the
  # store.
  networking.networkmanager.ensureProfiles = {
    environmentFiles = [ config.age.secrets.wireguard-medea-key.path ];
    profiles.wg-rhyzomatic = {
      connection = {
        id = "rhyzomatic.net";
        type = "wireguard";
        interface-name = "wg0";
        autoconnect = "false";
        permissions = "user:tancredi:";
      };
      wireguard.private-key = "$WG_PRIVATE_KEY";
      "wireguard-peer.${config.environment.wireguard.devices.creusa.publicKey}" = {
        endpoint = config.environment.wireguard.devices.creusa.endpoint;
        allowed-ips = "10.241.0.0/16";
        persistent-keepalive = "25";
      };
      ipv4 = {
        method = "manual";
        address1 = "10.241.46.10/24";
        dns = "10.241.23.1";
        dns-search = "rhyzomatic.net";
        dns-priority = "-10";
        never-default = "true";
      };
      ipv6.method = "disabled";
    };
  };
}
