final: prev: {
  python3Packages = prev.python3Packages // {
    yt-dlp = prev.python3Packages.yt-dlp.overrideAttrs (oldAttrs: rec {
      version = "2025.09.23";
      src = prev.fetchFromGitHub {
        owner = "yt-dlp";
        repo = "yt-dlp";
        rev = version;
        hash = "sha256-pqdR1JfiqvBs5vSKF7bBBKqq0DRAi3kXCN1zDvaW3nQ=";
      };
    });
  };
}
