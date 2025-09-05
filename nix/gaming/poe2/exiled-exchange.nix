{
  lib,
  fetchurl,
  stdenv,
  appimageTools,
  makeWrapper,
  electron,
  xorg,
}:
#basically based off of nezia's PR but for poe2 stuff
stdenv.mkDerivation rec {
  pname = "exiled-exchange-2";
  version = "0.11.5";
  src = fetchurl {
    url = "https://github.com/Kvan7/Exiled-Exchange-2/releases/download/v${version}/Exiled-Exchange-2-${version}.AppImage";
    hash = "sha256-bWwSQ9wVjL7vamfE6L95Oapjvms90lJw8IYJh32mLuw="; # Update this hash
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
    mkdir -p $out/bin $out/share/exiled-exchange-2 $out/share/applications
    cp -a ${appimageContents}/{locales,resources} $out/share/exiled-exchange-2
    cp -a ${appimageContents}/exiled-exchange-2.desktop $out/share/applications/
    cp -a ${appimageContents}/usr/share/icons $out/share
    substituteInPlace $out/share/applications/exiled-exchange-2.desktop \
    --replace-fail 'Exec=AppRun' 'Exec=exiled-exchange-2'
    runHook postInstall
  '';
  postFixup = ''
        makeWrapper ${lib.getExe electron} $out/bin/exiled-exchange-2 \
    --add-flags $out/share/exiled-exchange-2/resources/app.asar \
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
    maintainers = [ "ianhuezo" ];
    platforms = lib.platforms.linux;
    mainProgram = "exiled-exchange-2";
  };
}
