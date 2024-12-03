{ config, lib, ... }:

let
  datasetName = dataset: "${dataset.pool.name}/${dataset.name}";
in

{
  users.groups.storage = {
    gid = 5000;
  };

  storage.zpools = {
    system = {
      datasets = {
        "root" = { mountPoint = "/"; };
        "nix" = { mountPoint = "/nix"; };
        "state" = { mountPoint = config.environment.state; };
        "services" = { mountPoint = null; };
        "services/quassel" = { mountPoint = "/var/services/quassel"; };
        "services/syncthing" = { mountPoint = "/var/services/syncthing"; };
        "services/slskd" = { mountPoint = "/var/services/slskd"; };
        "home" = { mountPoint = null; };
        "home/tancredi" = { mountPoint = "/home/tancredi"; };
      };
    };
    storage = {
      datasets = {
        "books" = { mountPoint = "/mnt/storage/books"; };
        "papers" = { mountPoint = "/mnt/storage/papers"; };
        "music" = { mountPoint = null; };
        "music/electronic" = { mountPoint = "/mnt/storage/music/electronic"; };
      };
    };
    scratch = {
      datasets = {
        "downloads" = { mountPoint = null; };
        "downloads/slskd" = { mountPoint = "/mnt/scratch/downloads/slskd"; };
        "music-mp3" = { mountPoint = null; };
        "music-mp3/electronic" = { mountPoint = "/mnt/scratch/music-mp3/electronic"; };
        "music-opus" = { mountPoint = null; };
        "music-opus/electronic" = { mountPoint = "/mnt/scratch/music-opus/electronic"; };
      };
    };
    backup = { datasets = { }; };
  };

  services.zfs.autoScrub = {
    enable = true;
    # Run on the first Monday of every month at 02:00.
    interval = "Mon *-*-1..7 02:00:00";
  };

  services.zfs.trim = {
    enable = true;
    # Run on every Friday at 02:00.
    interval = "Fri *-*-* 02:00:00";
  };

  services.sanoid = {
    enable = true;
    extraArgs = [ "--verbose" ];
    datasets = let
      systemDatasets = config.storage.zpools.system.datasets;
      storageDatasets = config.storage.zpools.storage.datasets;
      backupPool = config.storage.zpools.backup;
      dailyCfg = {
        yearly = 0; monthly = 0; daily = 30; hourly = 0; frequently = 0;
        autosnap = true; autoprune = true; recursive = false;
      };
      backupCfg = {
        yearly = 0; monthly = 12; daily = 30; hourly = 48;
        autosnap = false; autoprune = true; recursive = true;
      };
    in {
      # The system state changes so slowly I manually snapshot it.
      # "${datasetName systemDatasets."state"}" = dailyCfg;
      "${datasetName systemDatasets."services/quassel"}" = dailyCfg;
      "${datasetName storageDatasets."books"}" = dailyCfg;
      "${datasetName storageDatasets."papers"}" = dailyCfg;
      "${datasetName storageDatasets."music/electronic"}" = dailyCfg;
      "${backupPool.name}" = backupCfg;
    };
  };

  services.syncoid = {
    enable = true;
    commands = let
      inherit (lib.attrsets) mergeAttrsList;

      systemDatasets = config.storage.zpools.system.datasets;
      storageDatasets = config.storage.zpools.storage.datasets;

      common = {
        extraArgs = [ "--no-sync-snap" "--no-resume" ];
        sendOptions = "Rw";
        recursive = false;
        localTargetAllow = [
          "change-key" "compression" "create" "mount" "mountpoint"
          "receive" "rollback" "acltype"
        ];
      };

      # type: str -> str -> str
      # Example:
      #  addPrefix "system/services/quassel"
      #  => "backup/system/services/quassel"
      addBackupPrefix = dataset:
        config.storage.zpools.backup.name + "/" + dataset;

      command = dataset: args: {
        "${datasetName dataset}" =
          { target = addBackupPrefix (datasetName dataset); } // args;
      };
    in mergeAttrsList [
      (command systemDatasets."state" common)
      (command systemDatasets."services/quassel" common)
      (command storageDatasets."books" common)
      (command storageDatasets."papers" common)
      (command storageDatasets."music/electronic" common)
    ];
  };
}
