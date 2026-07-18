{ flake, lib, ... }:

let
  inherit (lib) mkOption types;
  inherit (flake.lib.net.types) ipv4Address ipv4Cidr macAddress;

  network = import ../../../registry/network.nix;

  subnet = types.submodule {
    options.cidr = mkOption {
      type = ipv4Cidr;
      description = "Subnet in CIDR notation.";
    };
  };

  interface = types.submodule {
    options = {
      mac = mkOption {
        type = types.nullOr macAddress;
        default = null;
        description = "MAC address, when fixed and known (physical NICs).";
      };
      subnet = mkOption {
        type = types.nullOr (types.enum (lib.attrNames network.subnets));
        default = null;
        description = ''
          Name of the entry in environment.network.subnets this interface
          sits in; null for an address outside the site's subnets, such as
          a public IP. Typed as an enum of the declared subnets, so an
          unknown name fails at evaluation.
        '';
      };
      address = mkOption {
        type = types.nullOr ipv4Address;
        default = null;
        description = "Statically planned IPv4 address.";
      };
    };
  };

  host = types.submodule {
    options.interfaces = mkOption {
      type = types.attrsOf interface;
      default = {};
      description = "Interfaces, keyed by the registry's name for them.";
    };
  };

  target = types.submodule {
    options = {
      host = mkOption {
        type = types.enum (lib.attrNames network.hosts);
        description = ''
          Name of the entry in environment.network.hosts the record points
          at. Typed as an enum of the declared hosts, so an unknown name
          fails at evaluation.
        '';
      };
      interface = mkOption {
        type = types.str;
        description = ''
          Name of the interface on that host whose address answers the
          record. A plain string, since its valid values depend on the
          chosen host; tests/registry/network.nix checks it resolves.
        '';
      };
    };
  };

  mxEntry = types.submodule {
    options = {
      preference = mkOption {
        type = types.ints.unsigned;
        description = "MX preference; lower is tried first.";
      };
      exchange = mkOption {
        type = types.str;
        description = "Fully qualified mail exchanger name.";
      };
    };
  };

  # Exactly one kind of answer per record and view, as a tagged union.
  answer = types.attrTag {
    interface = mkOption {
      type = target;
      description = "A record answering with a registry interface's address.";
    };
    address = mkOption {
      type = ipv4Address;
      description = "A record answering with a literal address.";
    };
    cname = mkOption {
      type = types.str;
      description = "CNAME record answering with a fully qualified target.";
    };
    txt = mkOption {
      type = types.listOf types.str;
      description = "TXT record strings.";
    };
    mx = mkOption {
      type = types.listOf mxEntry;
      description = "MX record entries.";
    };
    ns = mkOption {
      type = types.listOf types.str;
      description = "NS record targets.";
    };
  };

  view = types.submodule {
    options.zones = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "Zone names this view answers for.";
    };
  };

  record = types.submodule {
    options = {
      name = mkOption {
        type = types.str;
        description = "Fully qualified DNS name.";
      };
      ptr = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether this is the canonical name for its address, emitted as
          the address's PTR record.
        '';
      };
      views = mkOption {
        type = types.submodule {
          options = lib.genAttrs (lib.attrNames network.dns.views) (view: mkOption {
            type = types.nullOr answer;
            default = null;
            description = ''
              Answer in the ${view} view; null when the name does not
              resolve there.
            '';
          });
        };
        default = {};
        description = ''
          Per-view answers. The option set is generated from dns.views, so
          a record naming an undeclared view fails at evaluation.
        '';
      };
    };
  };
in {
  options.environment.network = {
    subnets = mkOption {
      type = types.attrsOf subnet;
      readOnly = true;
      default = network.subnets;
      description = ''
        Site subnets, keyed by role name.

        This module is only the accessor: the topology lives in
        registry/network.nix.
      '';
    };

    hosts = mkOption {
      type = types.attrsOf host;
      readOnly = true;
      default = network.hosts;
      description = ''
        Addressable devices (managed hosts and site appliances), keyed by
        name, each carrying its interfaces' MACs and planned addresses.

        This module is only the accessor: the topology lives in
        registry/network.nix. A configuration references
        `config.environment.network.hosts.<host>.interfaces.<name>.address`
        and friends, so it is always clear whose address is meant.
      '';
    };

    dns = {
      views = mkOption {
        type = types.attrsOf view;
        readOnly = true;
        default = network.dns.views;
        description = ''
          Split-horizon views, keyed by name: each resolver serves exactly
          one view and answers for the zones listed in it. This module is
          only the accessor: the views live in registry/network.nix.
        '';
      };

      records = mkOption {
        type = types.attrsOf record;
        readOnly = true;
        default = network.dns.records;
        description = ''
          DNS names, keyed by a short slug, each answering per view with
          exactly one kind of record data (an interface reference or
          literal address/cname/txt/mx/ns data).

          This module is only the accessor: the records live in
          registry/network.nix. A configuration references a name as
          `config.environment.network.dns.records.<slug>.name`, so the
          name is spelled in exactly one place; a resolver derives its
          record set from the answers of its view.
        '';
      };
    };
  };
}
