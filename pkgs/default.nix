pkgs:

{
  actual-server = pkgs.callPackage ./actual-server.nix {};
  telegram-send = pkgs.callPackage ./telegram-send {};
}
