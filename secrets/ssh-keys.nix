# Public SSH keys. These are not secret, so they live here as plain data
# (cf. secrets/keys.nix, which holds the hosts' public age keys). Each
# entry is the public half of the correspondingly-named
# ssh-key-<name>.age private secret. It is surfaced by the
# environment.sshPublicKeys module, so host configs reference it as
# config.environment.sshPublicKeys.<name>, making clear which key is which.
{
  # Public half of ssh-key-creusa-root.age — root login on creusa.
  creusa-root =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEpTODCeryirxZzDL2CvPs7a8/oqjm2FRo8mCJ+nS6wA";

  # Public half of ssh-key-antigone-tancredi.age — login on antigone.
  antigone-tancredi =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIPLHIzL/1b7N08O3z7yRDsKI2vL4cyqxBaMonjlR7Ub";
}
