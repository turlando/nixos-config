pkgs:

{
  airdcpp = pkgs.callPackage ./airdcpp {};
  slskd = pkgs.callPackage ./slskd {};
  telegram-send = pkgs.callPackage ./telegram-send {};
}
