{ config, pkgs, ... }:

let
  get-dwproton = pkgs.writeShellScriptBin "dwproton.sh" ''
    set -ex
    export PATH="${pkgs.coreutils}/bin:${pkgs.curl}/bin:${pkgs.gnutar}/bin:${pkgs.xz}/bin:${pkgs.gnugrep}/bin:${pkgs.gnused}/bin:$PATH"
    # make temp working directory
    rm -rf /tmp/dwproton
    mkdir /tmp/dwproton
    cd /tmp/dwproton

    # scrape releases page to get latest version
    echo "Fetching latest dwproton version..."
    releases_page=$(curl -s https://dawn.wine/dawn-winery/dwproton/releases)
    latest_version=$(echo "$releases_page" | grep -oP 'dwproton-[0-9]+\.[0-9]+-[0-9]+' | head -n 1 | sed 's/dwproton-//')

    echo "Latest version: $latest_version"

    # construct download URLs
    tarball_url="https://dawn.wine/dawn-winery/dwproton/releases/download/dwproton-$latest_version/dwproton-$latest_version-x86_64.tar.xz"
    checksum_url="https://dawn.wine/dawn-winery/dwproton/releases/download/dwproton-$latest_version/dwproton-$latest_version-x86_64.sha512sum"

    tarball_name="dwproton-$latest_version-x86_64.tar.xz"
    checksum_name="dwproton-$latest_version-x86_64.sha512sum"

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

    # extract dwproton tarball to steam directory
    echo "Extracting to $compat_dir..."
    tar -xf "$tarball_name" -C "$compat_dir/"

    echo "DWProton $latest_version has been installed successfully!"
    echo "Restart Steam to see the new compatibility tool."
  '';
in
{
  environment.systemPackages = [ get-dwproton ];
}
