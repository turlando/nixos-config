# Syncthing device IDs, keyed by host. Like ssh-keys.nix, these are public
# identifiers, not secrets: each is the fingerprint of the corresponding
# syncthing-<host>-cert.age certificate, so it lives here as plain data.
# Surfaced by the environment.syncthingDeviceIds module; configurations
# reference an entry as config.environment.syncthingDeviceIds.<host> when
# declaring syncthing devices.
{
  antigone = "PWVWAK7-4LDFDEW-KO7PAOG-OMTBTTR-4JRSH3K-4YUEBNH-VK4XH5P-CGOPKQC";
}
