{ ... }:

let
  ref = s: "\${${s}}";

  hetzner-locations = {
    eu-central-nuremberg = "nbg1";
  };

  creusa = {
    location = hetzner-locations.eu-central-nuremberg;
  };
in
{
  terraform = {
    required_providers = {
      hcloud = {
        source = "hetznercloud/hcloud";
        version = "~> 1.60";
      };
    };
  };

  variable.hetzner_token_personal = {
    sensitive = true;
  };

  provider.hcloud = {
    token = ref "var.hetzner_token_personal";
  };

  resource.hcloud_primary_ip.creusa = {
    name = "creusa-ipv4";
    type = "ipv4";
    inherit (creusa) location;
    assignee_type = "server";
    auto_delete = false;
  };

  resource.hcloud_server.creusa = {
    name = "creusa";
    server_type = "cx23";
    inherit (creusa) location;
    image = "ubuntu-24.04";
    public_net = {
      ipv4_enabled = true;
      ipv4 = ref "hcloud_primary_ip.creusa.id";
      ipv6_enabled = false;
    };
    # ssh_keys and image were applied via cloud-init at creation. creusa
    # now runs NixOS via nixos-anywhere, so Hetzner cannot push changes
    # to either; both attributes are ForceNew on the provider, so
    # ignoring drift here prevents accidental destroy/recreate.
    lifecycle = {
      ignore_changes = [ "ssh_keys" "image" ];
    };
  };
}
