# Agenix recipients, keyed by host: each host carries its machine identity
# (the SSH host key, used by the nixos realm) and the per-user age identities
# that live on it (used by the home realm, and the infra realm for the OpenTofu
# token). Public halves only, so this is plain data; each user private half
# lives in ~/.config/agenix/key on that host. Surfaced by the
# environment.age.keys accessor; secrets/secrets.nix imports it directly to
# declare recipients.
{
  antigone = {
    host = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDRuCWecmULsH4Ir1TtZ+8uSbvV+h9fxZ7M6sop0bTIt";
    users = {
      tancredi = "age19jadg4l34x32s04p0w7m940p00eh6duwpmmnvw2azdxkp2qr5vqqp6kfsp";
    };
  };
  creusa = {
    host = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICKDnz+y6FOKXHKpogZFy/VZE8cWeN6wv6zAtF7FpNyK";
  };
  medea = {
    host = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOUPzIHyugVdG4WcMnlR75fqQqYon51NGa4Qf2f4hmPg";
    users = {
      luminovo = "age1g4nwnh2klfhkt6m0p0qnp24r45pe46w9fynk2qrc9edn08755ufshlc86r";
      tancredi = "age1qtyjch8puj9y0znnzrhmww6rw4lfp4zsycrkv7stp702vs5y6ymsrvual2";
    };
  };
}
