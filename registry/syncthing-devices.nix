# Syncthing devices, keyed by name. Each id is the fingerprint of that host's
# syncthing-<host>-cert.age certificate, so these are public identifiers, not
# secrets. Surfaced by the environment.syncthingDevices accessor; an entry maps
# directly onto services.syncthing.settings.devices.<name>, e.g.
# settings.devices.antigone = config.environment.syncthingDevices.antigone.
{
  antigone = {
    id = "PWVWAK7-4LDFDEW-KO7PAOG-OMTBTTR-4JRSH3K-4YUEBNH-VK4XH5P-CGOPKQC";
  };
  medea = {
    id = "4ZZJFM5-MIYT65O-LW3MP5L-E4Q24BH-EAAZSQJ-RQGNXPD-UOWTRZD-LWW7QAT";
  };
}
