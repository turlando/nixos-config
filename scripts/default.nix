inputs:

let
  scripts = {
    age-passwd = import ./age-passwd.nix inputs;
    nixos-install-remote = import ./nixos-install-remote.nix inputs;
  };

  apps = builtins.mapAttrs
    (name: drv: { type = "app"; program = "${drv}/bin/${name}"; })
    scripts;
in
{
  inherit scripts apps;
}
