{
  lib,
  fetchurl,
  appimageTools,
}:

let
  pname = "beyond-all-reason";
  version = "1.2988.0";
in
appimageTools.wrapType2 {
  inherit pname version;

  src = fetchurl {
    url = "https://github.com/beyond-all-reason/BYAR-Chobby/releases/download/v${version}/Beyond-All-Reason-${version}.AppImage";
    hash = "sha256-ZJW5BdxxqyrM2TJTO0SBp4BXt3ILyi77EZx73X8hqJE="; # Replace with actual hash
  };

  extraPkgs =
    pkgs: with pkgs; [
      # Dependencies from the Arch package list
      SDL2
      fuse
      openal
      gtk3
      alsa-lib
      nss
      binutils
    ];

  extraInstallCommands = ''
        mv $out/bin/${pname} $out/bin/bar
        
        # Create a desktop entry
        mkdir -p $out/share/applications
        cat > $out/share/applications/${pname}.desktop <<EOF
    [Desktop Entry]
    Name=Beyond All Reason
    Comment=Real-time strategy game
    Exec=bar
    Terminal=false
    Type=Application
    Categories=Game;StrategyGame;
    EOF
  '';

  meta = with lib; {
    description = "Free and open-source real-time strategy game";
    homepage = "https://www.beyondallreason.info/";
    changelog = "https://github.com/beyond-all-reason/BYAR-Chobby/releases/tag/v${version}";
    sourceProvenance = [ sourceTypes.binaryNativeCode ];
    license = licenses.gpl2Plus;
    platforms = platforms.linux;
    mainProgram = "bar";
  };
}
