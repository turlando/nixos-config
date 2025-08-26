let
  key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOUPzIHyugVdG4WcMnlR75fqQqYon51NGa4Qf2f4hmPg";
in {
  "ssh-key-github.age".publicKeys = [ key ];
  "ssh-key-gitlab-luminovo.age".publicKeys = [ key ];
  "ssh-key-tancredi.age".publicKeys = [ key ];
}
