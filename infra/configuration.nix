{ nixosConfigurations, ... }:

let
  ref = s: "\${${s}}";

  hetzner-locations = {
    eu-central-nuremberg = "nbg1";
  };

  creusa = {
    location = hetzner-locations.eu-central-nuremberg;
    ssh-public-key =
      builtins.elemAt
        nixosConfigurations.creusa.config.users.users.root.openssh.authorizedKeys.keys
        0;
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

  resource.hcloud_ssh_key.creusa-root = {
    name = "creusa-root";
    public_key = creusa.ssh-public-key;
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
    ssh_keys = [ (ref "hcloud_ssh_key.creusa-root.id") ];
    public_net = {
      ipv4_enabled = true;
      ipv4 = ref "hcloud_primary_ip.creusa.id";
      ipv6_enabled = false;
    };
  };
}
