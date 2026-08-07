{
  lib,
  stdenv,
  fetchzip,
  makeWrapper,
  autoPatchelfHook,
  bubblewrap,
  procps,
  socat,
}:
stdenv.mkDerivation rec {
  pname = "pi-coding-agent";
  version = "0.83.0";

  src = fetchzip {
    url = "https://github.com/earendil-works/pi/releases/download/v${version}/pi-linux-x64.tar.gz";
    hash = "sha256-QnhGPixOnMAy6nS5FGBKR7K30E9bpIYu4jtTUijuKFM=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
  ];

  buildInputs = [
    stdenv.cc.cc.lib
    procps
    bubblewrap
    socat
  ];

  dontBuild = true;
  dontConfigure = true;
  dontStrip = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    cp -r * $out/bin/
    runHook postInstall
  '';

  postFixup = ''
    wrapProgram $out/bin/pi \
      --prefix PATH : ${
        lib.makeBinPath [
          procps
          bubblewrap
          socat
        ]
      }
  '';

  meta = with lib; {
    description = "A harness for running pi";
    homepage = "https://github.com/earendil-works/pi";
    license = licenses.mit;
    maintainers = [ ];
    mainProgram = "pi";
    platforms = [ "x86_64-linux" ];
  };
}
