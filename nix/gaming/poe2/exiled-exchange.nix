{
  lib,
  fetchurl,
  stdenv,
  appimageTools,
  makeWrapper,
  electron,
  xorg,
}:
stdenv.mkDerivation rec {
  pname = "exiled-exchange";
  version = "3.26.101";
  src = fetchurl {
    url = "https://github.com/Kvan7/Exiled-Exchange-2/releases/download/v${version}/Exiled-Exchange-${version}.AppImage";
    hash = "sha256-n7xweAHNYQSDQMxZpHEf60PZk62ydwMsW9a7k3QeU1E=";
  };
  appimageContents = appimageTools.extractType2 {
    inherit pname src version;
  };
  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;
  nativeBuildInputs = [ makeWrapper ];
  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin $out/share/exiled-exchange $out/share/applications
    cp -a ${appimageContents}/{locales,resources} $out/share/exiled-exchange
    cp -a ${appimageContents}/exiled-exchange.desktop $out/share/applications/
    cp -a ${appimageContents}/usr/share/icons $out/share
    substituteInPlace $out/share/applications/exiled-exchange.desktop \
    --replace-fail 'Exec=AppRun' 'Exec=exiled-exchange'
    runHook postInstall
  '';
  postFixup = ''
        makeWrapper ${lib.getExe electron} $out/bin/exiled-exchange \
    --add-flags $out/share/exiled-exchange/resources/app.asar \
    --prefix LD_LIBRARY_PATH : "${
      lib.makeLibraryPath [
        xorg.libXtst
        xorg.libXt
      ]
    }"
  '';
  meta = {
    description = "Path of Exile trading app for price checking";
    homepage = "https://github.com/Kvan7/Exiled-Exchange-2";
    changelog = "https://github.com/Kvan7/Exiled-Exchange-2/releases/tag/v${version}";
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    license = lib.licenses.mit;
    maintainers = [ lib.maintainers.nezia ];
    platforms = lib.platforms.linux;
    mainProgram = "exiled-exchange";
  };
}
