{ config, pkgs, ... }:

{
  environment.defaults.enable = true;
  users.users.tancredi.extraGroups = [ config.users.groups.storage.name ]; 
  environment.systemPackages = with pkgs; [
    lm_sensors
    hddtemp
  ];
}
