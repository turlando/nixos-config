{ config, options, ... }:

let
  inherit (lib) mkIf;
in
{
  options = {
    services.openssh.hostKeys = let
      ephemeral = config.boot.ephemeral.enable;
      default = options.services.openssh.hostKeys.default;
    in
      mkIf
        ephemeral
        map
        (attr: updateManyAttrsByPath
          [ {
            path = [ "path" ];
            update = p: "${statePath}/${p}";
          } ]
          attr)
        default;
  };
}
