{ pkgs, ... }:
{
  environment.persistence.paths = [ "/etc/ssh" ];

  # Terminfo for the terminals we connect from (ghostty sets TERM=xterm-ghostty).
  environment.systemPackages = [ pkgs.ghostty.terminfo ];

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };
}
