# Network topology facts: the site's domain and subnets, every addressable
# device (managed hosts and site appliances alike) with its interfaces' MACs
# and planned addresses, and the DNS records binding names to those
# interfaces. Surfaced by the environment.network accessor; realm-agnostic
# plain data, so the infra realm can import it directly.
let
  rhyzomatic = "rhyzomatic.net";
  perosi = "perosi.${rhyzomatic}";
in
{
  subnets = {
    # Everything reachable over the site VPN, routed via the creusa hub.
    site = { cidr = "10.241.0.0/16"; };

    # The perosi apartment LAN behind antigone.
    lan = { cidr = "10.241.23.0/24"; };

    # Modem-to-antigone uplink segment.
    transit = { cidr = "10.241.254.0/24"; };

    # WireGuard overlay: the creusa hub, spokes, and roaming clients.
    wireguard = { cidr = "10.241.46.0/24"; };
  };

  hosts = {
    antigone = {
      interfaces = {
        # PCIe NIC (r8169), the trusted apartment LAN.
        lan0 = { mac = "c4:e9:84:04:c2:64"; subnet = "lan"; address = "10.241.23.1"; };

        # Builtin NIC (e1000e), uplink to the ZTE modem.
        wan0 = { mac = "10:7b:44:49:e6:8a"; subnet = "transit"; address = "10.241.254.2"; };

        wg0 = { subnet = "wireguard"; address = "10.241.46.2"; };

        # The initrd's unlock-only WireGuard identity (see
        # wireguard-devices.nix).
        wg0-initrd = { subnet = "wireguard"; address = "10.241.46.3"; };
      };
    };

    creusa = {
      interfaces = {
        # Hetzner primary IPv4, allocated by infra/configuration.nix.
        eth0 = { address = "46.225.229.141"; };
        wg0 = { subnet = "wireguard"; address = "10.241.46.1"; };
      };
    };

    medea = {
      interfaces = {
        wg0 = { subnet = "wireguard"; address = "10.241.46.10"; };
      };
    };

    # Site appliances, living under the perosi DNS subzone.
    ap0 = {
      interfaces.eth0 = { subnet = "lan"; address = "10.241.23.11"; };
    };

    modem = {
      interfaces.eth0 = { subnet = "transit"; address = "10.241.254.1"; };
    };
  };

  dns = {
    # Split-horizon views: one per resolver we run, listing the zones it
    # answers for. internal is served by antigone's unbound to LAN and VPN
    # clients. Zones we neither serve nor manage have no view here.
    views = {
      internal.zones = [ rhyzomatic ];
    };

    # Name-to-answer bindings, keyed by a short slug so configurations can
    # reference a name without respelling it. Per view, a record answers
    # with exactly one kind of data: an interface reference (an A record
    # from the registry's own topology) or literal
    # address/cname/txt/mx/ns data. ptr marks the canonical name for its
    # address.
    records = {
      antigone = {
        name = "antigone.${rhyzomatic}";
        ptr = true;
        views.internal.interface = { host = "antigone"; interface = "lan0"; };
      };

      slskd = {
        name = "slskd.antigone.${rhyzomatic}";
        views.internal.interface = { host = "antigone"; interface = "lan0"; };
      };

      syncthing = {
        name = "syncthing.antigone.${rhyzomatic}";
        views.internal.interface = { host = "antigone"; interface = "lan0"; };
      };

      ap0 = {
        name = "ap0.${perosi}";
        ptr = true;
        views.internal.interface = { host = "ap0"; interface = "eth0"; };
      };

      modem = {
        name = "modem.${perosi}";
        ptr = true;
        views.internal.interface = { host = "modem"; interface = "eth0"; };
      };

      # Points at creusa (nginx with ACME); the zone is managed by
      # freedns.afraid.org, not from here, so only the name is recorded.
      dracma = {
        name = "dracma.us.to";
      };
    };
  };
}
