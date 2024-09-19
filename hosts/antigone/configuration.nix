{ config, pkgs, ... }:

{
  environment.defaults.enable = true;
  users.users.tancredi.extraGroups = [ config.users.groups.storage.name ]; 
  hardware.opengl.enable = true;
  environment.systemPackages = with pkgs; [
    lm_sensors
    hddtemp
    waypipe
  ];
}
