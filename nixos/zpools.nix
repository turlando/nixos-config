{ config, lib, ... }:

let
  inherit (builtins) match;
  inherit (lib) mkOption types;
  inherit (lib.attrsets) concatMapAttrs filterAttrs getAttrFromPath mapAttrs;

  addCheckDesc = desc: elemType: check: types.addCheck
    elemType
    check // { description = "${elemType.description} (with check: ${desc})"; };

  isNonEmpty = s: (match "[ \t\n]*" s) == null;

  nonEmptyWithoutTrailingSlash = addCheckDesc
    "non-empty without trailing slash"
    types.str
    (s: isNonEmpty s && (match ".+/" s) == null);

  zfsFileSystem = pool: filesystem: mountPoint: {
    "${mountPoint}" = {
      device = "${pool}/${filesystem}";
      fsType = "zfs";
    };
  };
in

{
  options.storage.zpools = mkOption {
    type = types.attrsOf (types.submodule (
      { name, ... }@pool:
      {
        options = {
          name = mkOption {
            type = types.str;
            default = name;
            readOnly = true;
            visible = false;
          };
          datasets = mkOption {
            type = types.attrsOf (types.submodule (
              { name, ... }:
              {
                options = {
                  name = mkOption {
                    type = types.str;
                    default = name;
                    readOnly = true;
                    visible = false;
                  };
                  pool = mkOption {
                    default = pool;
                    readOnly = true;
                    visible = false;
                  };
                  mountPoint = mkOption {
                    type = types.nullOr nonEmptyWithoutTrailingSlash;
                    default = null;
                    example = "/var/log";
                    description = lib.mdDoc "Location of the mounted file system.";
                  };
                };
              }
            ));
          };
        };
      }
    ));
  };


  config = {
    fileSystems =
      concatMapAttrs
        (pool: poolAttrs:
          concatMapAttrs
            (dataset: datasetAttrs:
              zfsFileSystem pool dataset datasetAttrs.mountPoint)
            (filterAttrs
              (dataset: datasetAttrs: datasetAttrs.mountPoint != null)
              (getAttrFromPath ["datasets"] poolAttrs)))
        config.storage.zpools;
  };
}
