final: prev: {
  python3Packages = prev.python3Packages // {
    yt-dlp = prev.python3Packages.yt-dlp.overrideAttrs (oldAttrs: rec {
      version = "2025.08.11";
      src = prev.fetchFromGitHub {
        owner = "yt-dlp";
        repo = "yt-dlp";
        rev = version;
        sha256 = "sha256-HASH_HERE"; # You'll need to get this hash
      };
    });
  };
}
