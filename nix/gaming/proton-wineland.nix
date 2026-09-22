{ config, pkgs, ... }:

let
  get-proton-wineland = pkgs.writeShellScriptBin "proton-wineland.sh" ''
    set -ex
    export PATH="${pkgs.coreutils}/bin:${pkgs.curl}/bin:${pkgs.gnutar}/bin:${pkgs.xz}/bin:${pkgs.jq}/bin:${pkgs.gnugrep}/bin:$PATH"

    # x86_64, x86_64_v3 (AVX2) or x86_64_wow64
    variant="''${PROTON_WINELAND_VARIANT:-x86_64}"

    # make temp working directory
    rm -rf /tmp/proton-wineland
    mkdir /tmp/proton-wineland
    cd /tmp/proton-wineland

    echo "Fetching latest Proton Wineland release..."
    curl -s https://api.github.com/repos/nanomatters/proton-cachyos/releases/latest -o release.json

    tarball_url=$(jq -r --arg v "$variant" \
      '.assets[] | select(.name | endswith("-" + $v + ".tar.xz")) | .browser_download_url' release.json)
    checksum_url=$(jq -r --arg v "$variant" \
      '.assets[] | select(.name | endswith("-" + $v + ".sha512sum")) | .browser_download_url' release.json)

    if [ -z "$tarball_url" ]; then
      echo "No Proton Wineland asset for variant '$variant' in $(jq -r .tag_name release.json)" >&2
      exit 1
    fi

    tarball_name=$(basename "$tarball_url")
    checksum_name=$(basename "$checksum_url")

    # download tarball
    echo "Downloading $tarball_name..."
    curl -# -L "$tarball_url" -o "$tarball_name"

    # download checksum
    echo "Downloading checksum..."
    curl -# -L "$checksum_url" -o "$checksum_name"

    # check tarball with checksum
    echo "Verifying checksum..."
    sha512sum -c "$checksum_name"
    # if result is ok, continue

    # respect XDG_DATA_HOME so faugus-launcher / umu-launcher can find the runner
    compat_dir="''${XDG_DATA_HOME:-$HOME/.local/share}/Steam/compatibilitytools.d"
    mkdir -p "$compat_dir"

    echo "Extracting to $compat_dir..."
    tar -xf "$tarball_name" -C "$compat_dir/"

    # make steam directory if it does not exist
    mkdir -p ~/.steam/root/compatibilitytools.d
    tar -xf "$tarball_name" -C ~/.steam/root/compatibilitytools.d/

    echo "Proton Wineland ($variant) has been installed successfully!"
    echo "Restart Steam to see the new compatibility tool."
  '';
in
{
  environment.systemPackages = [ get-proton-wineland ];
}
