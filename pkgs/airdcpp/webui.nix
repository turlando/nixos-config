{ lib
, buildNpmPackage
, fetchFromGitHub
}:

buildNpmPackage {
  pname = "airdcpp-webui";
  version = "2.12.0";

  meta = {
    description = "";
    homepage = "";
    license = lib.licenses.gpl2;
    platforms = lib.platforms.linux;
  };


  src = fetchFromGitHub {
    owner = "airdcpp-web";
    repo = "airdcpp-webui";
    rev = "2.12.0";
    sha256 = "sha256-wIrJwWzomRasWS/HVhdmn6dnAqp1olfX1G73eYyL2wc=";
  };

  npmFlags = [ "--legacy-peer-deps" ];
  npmDepsHash = "sha256-b4Exqfd+O0dif9c61wSyEby3wMO9AhWTLLNrxMQ7bro=";

  installPhase = ''
    cp -r dist $out
  '';
}
