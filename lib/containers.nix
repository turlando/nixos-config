lib:

let
  inherit (lib.attrsets) mergeAttrsList;

  dataPath = "/data";

  dataBindMount = hostDataPath: {
    "${dataPath}" = {
      hostPath = hostDataPath;
      isReadOnly = false;
    };
  };

  hostBindMount = path: {
    "${path}" = {
      hostPath = path;
      isReadOnly = false;
    };
  };
in
{
  dataPath = dataPath;

  mkContainer = {
    name, # str
    config, # attrset
    data ? null, # str
    mounts ? [] # list str
  }: {
    "${name}" = {
      ephemeral = true;
      autoStart = true;

      bindMounts = mergeAttrsList 
        ((if data == null then [] else [ (dataBindMount data) ])
         ++ map hostBindMount mounts);

      # See https://github.com/NixOS/nixpkgs/issues/196370
      extraFlags = [
        "--resolv-conf=bind-host"
      ];

      config = config;
    };
  };
}
