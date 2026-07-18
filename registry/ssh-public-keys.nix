# Public SSH keys. These are not secret, so they live here as plain data
# (cf. age-keys.nix, which holds the hosts' public age keys). Each
# entry is the public half of the correspondingly-named ssh-key_<name>.age
# private secret and shares its tuple name
#   <target_host>-<target_user>_<source_host>-<source_user>
# (see secrets/secrets.nix). It is surfaced by the environment.ssh.publicKeys
# module, so host configs reference it as
# config.environment.ssh.publicKeys.<name> when populating the target's
# authorized_keys. Keys for external services (github/gitlab/compiler) are
# registered with the service instead, so they have no public half here.
{
  # -> root@creusa, from tancredi@medea
  creusa-root_medea-tancredi =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEpTODCeryirxZzDL2CvPs7a8/oqjm2FRo8mCJ+nS6wA";

  # -> root@antigone, from tancredi@medea
  antigone-root_medea-tancredi =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIPLHIzL/1b7N08O3z7yRDsKI2vL4cyqxBaMonjlR7Ub";

  # -> tancredi@antigone, from tancredi@medea
  antigone-tancredi_medea-tancredi =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICpg4hmvX07NutPjp71CD/4Kx5ezzuheO+7HUD4DLqur";
}
