{ lib

, callPackage
, fetchFromGitHub
, stdenv

, cmake
, pkg-config

, boost
, bzip2
, libmaxminddb
, leveldb
, miniupnpc
, openssl
, python3
, websocketpp
, zlib 
}:

let
  webui = callPackage ./webui.nix {};
in

stdenv.mkDerivation {
  pname = "airdcpp";
  version = "2.12.1";

  meta = {
    description = "";
    homepage = "";
    license = lib.licenses.gpl2;
    platforms = lib.platforms.linux;
  };

  src = fetchFromGitHub {
    owner = "airdcpp-web";
    repo = "airdcpp-webclient";
    rev = "2.12.1";
    sha256 = "sha256-ThNEpPAHT+GlDdKmETxxaq1Q/6dFyHO73J1hWgSnJNc=";
  };

  nativeBuildInputs = [ cmake pkg-config ];
  buildInputs = [ boost bzip2 libmaxminddb leveldb miniupnpc openssl
                  python3 websocketpp zlib ];

  cmakeFlags = [
    "-DINSTALL_WEB_UI=OFF"
  ];

  postInstall = ''
    mkdir -p $out/share/airdcpp
    ln -s ${webui} $out/share/airdcpp/web-resources
  '';
}
