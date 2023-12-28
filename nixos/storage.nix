{ config, lib, ... }:

let
  inherit (builtins) match;
  inherit (lib) mkDoc mkOption types;
  inherit (lib.attrsets) attrValues concatMapAttrs filterAttrs getAttrFromPath mapAttrs mergeAttrsets;
  inherit (lib.filesystems) zfsFileSystem;
  inherit (lib.lists) concatMap;

  addCheckDesc = desc: elemType: check: types.addCheck
    elemType
    check // { description = "${elemType.description} (with check: ${desc})"; };

  isNonEmpty = s: (match "[ \t\n]*" s) == null;

  nonEmptyWithoutTrailingSlash = addCheckDesc
    "non-empty without trailing slash"
    types.str
    (s: isNonEmpty s && (match ".+/" s) == null);

  mountPointOption = mkOption {
    type = types.nullOr nonEmptyWithoutTrailingSlash;
    example = "/var/log";
    description = lib.mdDoc "Location of the mounted file system.";
  };
in
{
  options = {
    storage.pools = mkOption {
      type = types.attrsOf (types.submodule (
        { ... }:
        {
          options = {
            datasets = mkOption {
              type = types.attrsOf (types.submodule (
                { ... }:
                {
                  options = {
                    mountPoint = mountPointOption;
                  };
                }
              ));
            };
          };
        }
      ));
    };
  };

  config = {
    fileSystems =
      concatMapAttrs
        (pool: poolAttrs: concatMapAttrs
          (dataset: datasetAttrs:
            zfsFileSystem pool dataset datasetAttrs.mountPoint)
          (filterAttrs
            (dataset: datasetAttrs: datasetAttrs.mountPoint != null)
            (getAttrFromPath ["datasets"] poolAttrs)))
        config.storage.pools;
  };
}
