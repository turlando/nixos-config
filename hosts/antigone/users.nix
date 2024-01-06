{ config, pkgs, lib, ... }:

let
  inherit (config.users) groups;
in
{
  users.users.tancredi.extraGroups = [ groups.storage.name ]; 
}
