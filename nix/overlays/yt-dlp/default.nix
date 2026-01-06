final: prev: {
  python3Packages = prev.python3Packages // {
    yt-dlp = prev.python3Packages.yt-dlp.overrideAttrs (oldAttrs: rec {
      version = "2025.10.22";
      src = prev.fetchFromGitHub {
        owner = "yt-dlp";
        repo = "yt-dlp";
        rev = version;
        hash = "sha256-jQaENEflaF9HzY/EiMXIHgUehAJ3nnDT9IbaN6bDcac";
      };
      patches = [ ]; # Clear patches from the base package that don't apply to this version
      postPatch = ""; # Clear postPatch phase that references files that don't exist in this version
    });
  };
}
