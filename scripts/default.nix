inputs:

let
  scripts = {
    age-passwd = import ./age-passwd.nix inputs;
  };

  apps = builtins.mapAttrs
    (name: drv: { type = "app"; program = "${drv}/bin/${name}"; })
    scripts;
in
{
  inherit scripts apps;
}
