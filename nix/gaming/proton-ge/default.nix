{
  lib,
  stdenv,
  fetchFromGitHub,
  curl,
  jq,
  makeWrapper,
  coreutils,
  gnutar,
  symlinkJoin,
}:

let
  pname = "proton-ge-custom";
  version = "latest";

  # Define Steam compatibility tools path
  steamCompatPath = "$HOME/.steam/root/compatibilitytools.d";
in
symlinkJoin {
  inherit pname version;

  name = "${pname}-${version}";

  nativeBuildInputs = [
    curl
    jq
    makeWrapper
  ];

  buildInputs = [
    (stdenv.mkDerivation {
      inherit pname version;

      dontUnpack = true;
      dontBuild = true;

      installPhase = ''
        # Create base directory
        mkdir -p $out/share/proton-ge

        # Get latest release info
        RELEASE_INFO=$(curl -s https://api.github.com/repos/GloriousEggroll/proton-ge-custom/releases/latest)

        # Get download URLs
        TARBALL_URL=$(echo "$RELEASE_INFO" | jq -r '.assets[] | select(.name | endswith(".tar.gz")) | .browser_download_url')
        CHECKSUM_URL=$(echo "$RELEASE_INFO" | jq -r '.assets[] | select(.name | endswith(".sha512sum")) | .browser_download_url')

        # Download files
        curl -L "$TARBALL_URL" -o proton.tar.gz
        curl -L "$CHECKSUM_URL" -o proton.sha512sum

        # Verify checksum
        sha512sum -c proton.sha512sum

        # Extract to our package directory
        tar -xf proton.tar.gz -C $out/share/proton-ge/
      '';

      meta = with lib; {
        description = "Proton GE (GloriousEggroll) for Steam Play";
        homepage = "https://github.com/GloriousEggroll/proton-ge-custom";
        license = licenses.bsd3;
        platforms = platforms.linux;
        maintainers = [ ];
      };
    })
  ];

  # Create setup script
  postBuild = ''
    mkdir -p $out/bin

    # Create setup script
    cat > $out/bin/setup-proton-ge << EOF
    #!${stdenv.shell}
    set -eu
    mkdir -p "${steamCompatPath}"
    ln -sfn $out/share/proton-ge/* "${steamCompatPath}/"
    echo "Proton GE has been installed to ${steamCompatPath}"
    EOF

    chmod +x $out/bin/setup-proton-ge
  '';
}
