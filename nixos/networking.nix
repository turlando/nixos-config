{ config, lib, options, ... }:

let
  inherit (lib) mkIf mkMerge;
  inherit (lib.attrsets) updateManyAttrsByPath;
in
{
  config = {
    services.openssh.hostKeys = let
      ephemeral = config.boot.ephemeral.enable;
      stateDir = config.boot.ephemeral.stateDir;
      default = options.services.openssh.hostKeys.default;
      new =  map
        (attr: updateManyAttrsByPath
          [ {
            path = [ "path" ];
            update = p: "${toString stateDir}/${p}";
          } ]
          attr)
        default;
    in mkIf ephemeral new;
  };
}
