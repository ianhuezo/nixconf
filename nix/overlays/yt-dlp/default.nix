final: prev: {
  python3Packages = prev.python3Packages // {
    yt-dlp = prev.python3Packages.yt-dlp.overrideAttrs (oldAttrs: rec {
      version = "2025.09.26";
      src = prev.fetchFromGitHub {
        owner = "yt-dlp";
        repo = "yt-dlp";
        rev = version;
        hash = "sha256-/uzs87Vw+aDNfIJVLOx3C8RyZvWLqjggmnjrOvUX1Eg=";
      };
    });
  };
}
