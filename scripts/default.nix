args:

let
  scripts = {
    age-edit = import ./age-edit.nix args;
    age-install-key = import ./age-install-key.nix args;
    age-install-user-key = import ./age-install-user-key.nix args;
    age-keygen = import ./age-keygen.nix args;
    age-passwd = import ./age-passwd.nix args;
    age-read = import ./age-read.nix args;
    age-rekey = import ./age-rekey.nix args;
    age-user-keygen = import ./age-user-keygen.nix args;
    disko-apply-remote = import ./disko-apply-remote.nix args;
    home-switch-remote = import ./home-switch-remote.nix args;
    infra-build = import ./infra-build.nix args;
    infra-tofu = import ./infra-tofu.nix args;
    nixos-install-remote = import ./nixos-install-remote.nix args;
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
