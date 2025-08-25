let
  key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOUPzIHyugVdG4WcMnlR75fqQqYon51NGa4Qf2f4hmPg";
in {
  "users-root-password.age".publicKeys = [ key ];
  "users-tancredi-password.age".publicKeys = [ key ];
}
