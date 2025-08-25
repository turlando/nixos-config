{ config, ... }:

{
  users.users.root = {
    hashedPasswordFile = config.age.secrets.users-root-password.path;
  };
}
