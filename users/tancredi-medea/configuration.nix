{ config, pkgs, ... }:

{
  home.stateVersion = "26.05";
  home.username = "tancredi";
  home.homeDirectory = "/home/tancredi";

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings = {
      "antigone" = {
        HostName = config.environment.network.hosts.antigone.interfaces.lan0.address;
        # tancredi by default; `ssh root@antigone` picks the root key from the
        # list (the tancredi key is offered first and simply rejected for root).
        User = "tancredi";
        IdentityFile = [
          config.age.secrets.ssh-key_antigone-tancredi_medea-tancredi.path
          config.age.secrets.ssh-key_antigone-root_medea-tancredi.path
        ];
      };
      "antigone-unlock" = {
        HostName = config.environment.network.hosts.antigone.interfaces.lan0.address;
        Port = 2222;
        User = "root";
        IdentityFile = config.age.secrets.ssh-key_antigone-root_medea-tancredi.path;
      };
      "creusa" = {
        HostName = config.environment.network.hosts.creusa.interfaces.eth0.address;
        User = "root";
        IdentityFile = config.age.secrets.ssh-key_creusa-root_medea-tancredi.path;
      };
      "github.com" = {
        HostName = "github.com";
        User = "git";
        IdentityFile = config.age.secrets.ssh-key_github-git_medea-tancredi.path;
      };
    };
  };

  programs.firefox.enable = true;
  programs.firefox.enableSmartCardSupport = true;
  programs.firefox.profiles.tancredi = {
    id = 0;
    isDefault = true;
    enableCustomDefaults = true;
  };

  programs.thunderbird.enable = true;
  programs.thunderbird.profiles.tancredi = {
    isDefault = true;
    enableCustomDefaults = true;
  };

  programs.emacs.enable = true;
  programs.emacs.package = pkgs.emacs-pgtk;

  # User-level syncthing with a TLS identity pinned from agenix, fixing medea's
  # device ID (its entry in the syncthing device registry). The GUI stays on
  # the default loopback, reached locally.
  services.syncthing = {
    enable = true;
    cert = config.age.secrets.syncthing-medea-cert.path;
    key = config.age.secrets.syncthing-medea-key.path;

    settings.devices.antigone = config.environment.syncthing.devices.antigone;

    settings.folders."electronic-mp3" = {
      label = "Electronic (MP3)";
      path = "/srv/music/electronic";
      type = "receiveonly";
      # antigone's files are group-restricted (o=---); take medea's umask
      # instead so the library stays world-readable for the libvirt VM.
      ignorePerms = true;
      devices = [ "antigone" ];
    };
  };

  # syncthing's copy-keys step installs the pinned cert from agenix, so order
  # it after the home secrets are decrypted; otherwise it races agenix on login
  # and the service fails until a retry.
  systemd.user.services.syncthing.Unit = {
    After = [ "agenix.service" ];
    Requires = [ "agenix.service" ];
  };

  home.packages = [
    pkgs.kdePackages.krdc
  ];
}
