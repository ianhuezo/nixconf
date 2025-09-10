final: prev: {
  python3Packages = prev.python3Packages // {
    yt-dlp = prev.python3Packages.yt-dlp.overrideAttrs (oldAttrs: rec {
      version = "2025.09.05";
      src = prev.fetchFromGitHub {
        owner = "yt-dlp";
        repo = "yt-dlp";
        rev = version;
        hash = "sha256-9y6OUVm6hNTTi5FFmd9DHcmAMrvSmDD+4kDe00aMTDI=";
      };
    });
  };
}
