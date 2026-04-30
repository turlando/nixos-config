inputs:

let
  scripts = {
    age-install-key = import ./age-install-key.nix inputs;
    age-passwd = import ./age-passwd.nix inputs;
    disko-apply-remote = import ./disko-apply-remote.nix inputs;
    nixos-install-remote = import ./nixos-install-remote.nix inputs;
  };

  apps = builtins.mapAttrs
    (name: drv: { type = "app"; program = "${drv}/bin/${name}"; })
    scripts;
in
{
  inherit scripts apps;
}
