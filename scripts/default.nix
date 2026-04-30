_:

let
  scripts = {
    # writeShellApplication scripts will be added here.
  };

  apps = builtins.mapAttrs
    (name: drv: { type = "app"; program = "${drv}/bin/${name}"; })
    scripts;
in
{
  inherit scripts apps;
}
