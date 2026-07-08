inputs:

let
  scripts = {
    age-edit = import ./age-edit.nix inputs;
    age-install-key = import ./age-install-key.nix inputs;
    age-keygen = import ./age-keygen.nix inputs;
    age-passwd = import ./age-passwd.nix inputs;
    age-read = import ./age-read.nix inputs;
    age-rekey = import ./age-rekey.nix inputs;
    disko-apply-remote = import ./disko-apply-remote.nix inputs;
    home-switch-remote = import ./home-switch-remote.nix inputs;
    infra-build = import ./infra-build.nix inputs;
    infra-tofu = import ./infra-tofu.nix inputs;
    nixos-install-remote = import ./nixos-install-remote.nix inputs;
  };

  apps = builtins.mapAttrs
    (name: drv: {
      type = "app";
      program = "${drv}/bin/${name}";
      meta = drv.meta or {};
    })
    scripts;
in
{
  inherit scripts apps;
}
