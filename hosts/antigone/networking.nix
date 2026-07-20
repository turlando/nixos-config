{ config, flake, lib, pkgs, ... }:
let
  inherit (flake.lib) net;
  inherit (config.environment.network) dns hosts subnets;

  antigone = hosts.antigone.interfaces;

  # Where boot.initrd.secrets bakes the initrd WG key and networkd reads it,
  # named once so the two references cannot drift apart.
  initrdWgKey = "/etc/wireguard-initrd.key";
in
{
  # Remote unlock: the initrd-openssh-server profile runs sshd (:2222) with a
  # persistent host key. lan0 unlocks from the LAN; wan0 plus a wg0 tunnel
  # dialing the creusa hub unlock over the VPN (ssh -p 2222 root@10.241.46.3),
  # reachable before the pool mounts. lan0 unlock is unaffected and stays the
  # fallback. The tunnel key is a separate unlock-only agenix secret, baked
  # into the initrd from /run/agenix at switch time; like the initrd host key
  # it lives unencrypted on the ESP, so creusa scopes its peer to its own
  # address.
  boot.initrd.availableKernelModules = [ "e1000e" "r8169" ];
  boot.initrd.kernelModules = [ "wireguard" ];

  # In the initrd, networkd runs as the unprivileged systemd-network user and
  # must read this key to build wg0. The initrd-secrets cpio forces root:root
  # ownership, so a group grant cannot reach it: the key has to be
  # world-readable. That adds no exposure, as it is already baked unencrypted
  # onto the ESP.
  age.secrets.wireguard-antigone-initrd-key.mode = "0444";
  boot.initrd.secrets.${initrdWgKey} = config.age.secrets.wireguard-antigone-initrd-key.path;

  boot.initrd.systemd.network = {
    enable = true;

    netdevs."10-wg0" = {
      netdevConfig = { Name = "wg0"; Kind = "wireguard"; };
      wireguardConfig.PrivateKeyFile = initrdWgKey;
      wireguardPeers = [
        {
          PublicKey = config.environment.wireguard.devices.creusa.publicKey;
          Endpoint = config.environment.wireguard.devices.creusa.endpoint;
          AllowedIPs = [ subnets.wireguard.cidr ];
          PersistentKeepalive = 25;
        }
      ];
    };

    networks = {
      "10-lan0" = {
        matchConfig.MACAddress = antigone.lan0.mac;
        address = [ (net.withPrefix antigone.lan0.address subnets.lan.cidr) ];
      };
      "10-wan0" = {
        matchConfig.MACAddress = antigone.wan0.mac;
        address = [ (net.withPrefix antigone.wan0.address subnets.transit.cidr) ];
        gateway = [ hosts.modem.interfaces.eth0.address ];
      };
      "10-wg0" = {
        matchConfig.Name = "wg0";
        address = [ (net.withPrefix antigone.wg0-initrd.address subnets.wireguard.cidr) ];
      };
    };
  };

  boot.initrd.network.ssh.authorizedKeys = [ config.environment.ssh.publicKeys.antigone-root_medea-tancredi ];

  # Pin interface names by MAC so they stay stable across reboots and as
  # NICs are added.

  # wan0: builtin NIC (e1000e), uplink to the ZTE modem.
  systemd.network.links."10-wan0" = {
    matchConfig.MACAddress = antigone.wan0.mac;
    linkConfig.Name = "wan0";
  };

  # lan0: PCIe NIC (r8169), the trusted apartment LAN.
  systemd.network.links."10-lan0" = {
    matchConfig.MACAddress = antigone.lan0.mac;
    linkConfig.Name = "lan0";
  };

  # Networking backend: systemd-networkd. wan0 is antigone's static uplink
  # to the ZTE on the transit segment; lan0 is the static LAN gateway.
  # wait-online is disabled so a down WAN or idle LAN never blocks or
  # degrades boot; services self-heal as links come up.
  networking.useDHCP = false;
  networking.useNetworkd = true;
  systemd.network.wait-online.enable = false;

  systemd.network.networks = {
    "10-wan0" = {
      matchConfig.Name = "wan0";
      address = [ (net.withPrefix antigone.wan0.address subnets.transit.cidr) ];
      gateway = [ hosts.modem.interfaces.eth0.address ];
    };
    "10-lan0" = {
      matchConfig.Name = "lan0";
      address = [ (net.withPrefix antigone.lan0.address subnets.lan.cidr) ];
    };
  };

  # NAT: masquerade lan0 traffic out wan0 so LAN clients reach the
  # internet; NAT also emits the matching forward accepts. Containers that
  # earn internet egress add their own address to internalIPs next to
  # their definition in containers/.
  networking.nat = {
    enable = true;
    externalInterface = "wan0";
    internalInterfaces = [ "lan0" ];
  };

  # Firewall: nftables, default-deny on input and forward. lan0 (the
  # apartment LAN) and wg0 (the VPN) are trusted for input, so both reach
  # antigone's own services; wan0 stays default-deny inbound, passing only
  # conntrack-established return traffic. filterForward drops routed flows
  # by default and accepts DNAT'd ones; LAN and VPN keep forwarding to each
  # other, and each container's flows are declared next to it in
  # containers/. The VPN is split-tunnel, so wg0 gets no internet egress.
  networking.nftables.enable = true;
  networking.firewall.filterForward = true;
  networking.firewall.trustedInterfaces = [ "lan0" "wg0" ];
  networking.firewall.extraForwardRules = ''
    iifname { "lan0", "wg0" } oifname { "lan0", "wg0" } accept
  '';

  # SSH is management: reachable over the trusted interfaces (lan0 and the
  # wg0 VPN), never on wan0, the internet edge under DMZ.
  services.openssh.openFirewall = false;

  # WireGuard spoke. antigone dials out to the creusa hub (stable public IP)
  # and holds the tunnel open with keepalive, so it stays reachable across the
  # rotating WAN with no dynamic DNS. allowedIPs covers the WG transit, so
  # replies to roaming clients route back through creusa. antigone initiates,
  # so no inbound port is opened on wan0; creusa's replies return established.
  networking.wireguard.interfaces.wg0 = {
    ips = [ (net.withPrefix antigone.wg0.address subnets.wireguard.cidr) ];
    privateKeyFile = config.age.secrets.wireguard-antigone-key.path;
    peers = [
      {
        publicKey = config.environment.wireguard.devices.creusa.publicKey;
        endpoint = config.environment.wireguard.devices.creusa.endpoint;
        allowedIPs = [ subnets.wireguard.cidr ];
        persistentKeepalive = 25;
      }
    ];
  };

  # DHCP: kea serves the LAN on lan0, handing out antigone as gateway and
  # resolver.
  services.kea.dhcp4 = {
    enable = true;
    settings = {
      interfaces-config.interfaces = [ "lan0" ];
      lease-database = {
        type = "memfile";
        persist = true;
        name = "/var/lib/kea/dhcp4.leases";
      };
      valid-lifetime = 86400;
      subnet4 = [
        {
          id = 1;
          subnet = subnets.lan.cidr;
          pools = [ { pool = "10.241.23.101 - 10.241.23.200"; } ];
          option-data = [
            { name = "routers";             data = antigone.lan0.address; }
            { name = "domain-name-servers"; data = antigone.lan0.address; }
          ];
        }
      ];
    };
  };

  # antigone resolves through unbound, not systemd-resolved (which would
  # otherwise use the wan0 link's DNS, i.e. the modem). With resolved off,
  # resolveLocalQueries points antigone's /etc/resolv.conf straight at
  # unbound.
  services.resolved.enable = false;

  # DNS: unbound is the caching resolver for antigone, the LAN, and roaming
  # WireGuard clients. It forwards to Quad9 over DoT and serves the internal
  # split-horizon view of the registry: the view's zones are declared static
  # below and its records become the A and PTR data. resolveLocalQueries
  # points antigone's own queries here too.
  services.unbound = let
    view = dns.views.internal;

    # The records answered in the internal view, e.g.
    #   { name = "antigone.rhyzomatic.net"; ptr = true;
    #     answer.interface = { host = "antigone"; interface = "lan0"; }; }
    servedRecords = lib.mapAttrsToList
      (_: record: { inherit (record) name ptr; answer = record.views.internal; })
      (lib.filterAttrs (_: record: record.views.internal != null) dns.records);

    # local-data line for one served record: CNAME answers verbatim,
    # address-bearing answers as A records resolved through the registry.
    recordLine = record:
      if record.answer ? cname
      then ''"${record.name}. IN CNAME ${record.answer.cname}"''
      else ''"${record.name}. IN A ${net.answerAddress hosts record.answer}"'';
  in {
    enable = true;
    resolveLocalQueries = true;
    settings = {
      server = {
        interface = [
          "127.0.0.1"
          antigone.lan0.address
        ];
        access-control = [
          "127.0.0.0/8 allow"
          "${subnets.lan.cidr} allow"
          "${subnets.wireguard.cidr} allow"
        ];

        tls-cert-bundle = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";

        # The view's zones answered authoritatively, with static cutting any
        # fallthrough to the forwarders, e.g. '"rhyzomatic.net." static'.
        local-zone =
          map (zone: ''"${zone}." static'') view.zones
          # Reverse zones for the subnets antigone does reverse DNS for,
          # named after their CIDRs, e.g. '"23.241.10.in-addr.arpa." static'.
          ++ map (subnet: ''"${net.reverseZone subnet.cidr}." static'') [
            subnets.lan
            subnets.transit
          ];

        # One line per served record, e.g.
        # '"antigone.rhyzomatic.net. IN A 10.241.23.1"'.
        local-data = map recordLine servedRecords;

        # One PTR record per address, from the record marked as the
        # address's canonical name, e.g. '"10.241.23.1 antigone.rhyzomatic.net"'.
        local-data-ptr = map
          (record: ''"${net.answerAddress hosts record.answer} ${record.name}"'')
          (lib.filter (record: record.ptr) servedRecords);
      };

      forward-zone = [
        {
          name = ".";
          forward-tls-upstream = true;
          forward-addr = [
            "9.9.9.9@853#dns.quad9.net"
            "149.112.112.112@853#dns.quad9.net"
          ];
        }
      ];
    };
  };
}
