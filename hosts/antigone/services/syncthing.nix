{ config, lib, ... }:

let
  inherit (lib.containers) dataPath mkContainer;

  storageGroup = config.users.groups.storage;

  systemDatasets = config.storage.pools.system.datasets;
  storageDatasets = config.storage.pools.storage.datasets;
  scratchDatasets = config.storage.pools.scratch.datasets;

  antigoneId = "6YAFIOP-Y6TGT4V-FPT77ER-YZMJODJ-533JSKV-FJ5IFOW-QNVMVAV-32XR6AR";
  bahnhofId = "USBCMJL-WXMG4PP-XC364HB-OKBWEVH-HGKVW6E-T2YML7O-56BMQMH-3P7BUAP";
  tersicoreId = "FM5JR2N-PM7ZAHY-MDCOE35-O2JPFVC-WAQVIE7-BGSCIE5-RTL25WO-TG2Z6AY";
  smartphoneId = "OF5ZIAD-MQ5C6JC-7LVLTSJ-EP4LLXX-ZVVXD7J-72PQQRU-KWFDLD3-XKOSPQ5";
  tabletId = "RLGYY64-A45GLZF-I6SHORQ-4YQCNO6-U4NNPIS-BBUPTTG-QPCTXVW-RFQJYAO";
in
{
  networking.firewall = {
    allowedTCPPorts = [ 22000 ];
    allowedUDPPorts = [ 21027 22000 ];
  };

  containers = mkContainer {
    name = "syncthing";
    data = systemDatasets."services/syncthing".mountPoint;
    mounts = [
      storageDatasets."books".mountPoint
      storageDatasets."papers".mountPoint
      scratchDatasets."music-opus/electronic".mountPoint
      scratchDatasets."music-mp3/electronic".mountPoint
    ];
    config =
      { config, pkgs, ... }:
      {
        system.stateVersion = "23.11";

        users.groups = {
          storage = storageGroup;
        };

        users.users.syncthing = {
          extraGroups = [ storageGroup.name ];
        };

        services.syncthing = {
          enable = true;
          configDir = dataPath;
          guiAddress = "127.0.0.1:8383";
          openDefaultPorts = true;

          settings.devices = {
            Antigone.id = antigoneId;
            Bahnhof.id = bahnhofId;
            Tersicore.id = tersicoreId;
            Smartphone.id = smartphoneId;
            Tablet.id = tabletId;
          };

          settings.folders = let
            devices = config.services.syncthing.settings.devices;
          in {
            books = {
              label = "Books";
              path = storageDatasets."books".mountPoint;
              type = "sendonly";
              devices = [
                devices.Bahnhof.name
                devices.Tablet.name
              ];
            };
            papers = {
              label = "Papers";
              path = storageDatasets."papers".mountPoint;
              type = "sendonly";
              devices = [
                devices.Bahnhof.name
                devices.Tablet.name
              ];
            };
            music-opus-electronic = {
              label = "Music (Opus) - Electronic";
              path = scratchDatasets."music-opus/electronic".mountPoint;
              type = "sendonly";
              devices = [
                devices.Smartphone.name
              ];
            };
            music-mp3-electronic = {
              label = "Music (MP3) - Electronic";
              path = scratchDatasets."music-mp3/electronic".mountPoint;
              type = "sendreceive";
              devices = [
                devices.Tersicore.name
              ];
            };
          };
        };
      };
  };
}
