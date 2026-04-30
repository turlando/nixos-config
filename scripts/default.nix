inputs:

let
  scripts = {
    age-edit = import ./age-edit.nix inputs;
    age-install-key = import ./age-install-key.nix inputs;
    age-passwd = import ./age-passwd.nix inputs;
    age-read = import ./age-read.nix inputs;
    age-rekey = import ./age-rekey.nix inputs;
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
