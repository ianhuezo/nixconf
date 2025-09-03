final: prev: {
  python3Packages = prev.python3Packages // {
    yt-dlp = prev.python3Packages.yt-dlp.overrideAttrs (oldAttrs: rec {
      version = "2025.08.11";
      src = prev.fetchFromGitHub {
        owner = "yt-dlp";
        repo = "yt-dlp";
        rev = version;
        sha256 = "sha256-j7x844MPPFdXYTJiiMnru3CE79A/6JdfJDdh8it9KsU=";
      };
    });
  };
}
