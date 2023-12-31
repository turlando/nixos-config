pkgs:

{
  slskd = pkgs.callPackage ./slskd {};
  telegram-send = pkgs.callPackage ./telegram-send {};
}
