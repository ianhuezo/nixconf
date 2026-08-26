final: prev: {
  python3Packages = prev.python3Packages // {
    # nixpkgs lags yt-dlp badly; a stale yt-dlp gets HTTP 403 on YouTube audio
    # downloads once YouTube retires whichever player client it was falling back
    # to (android_vr -> visionos as of 2026.08). Bump this pin when that happens.
    # Keep patches/postPatch from the base package -- postPatch is what wires
    # deno in for JS challenges.
    yt-dlp = prev.python3Packages.yt-dlp.overrideAttrs (oldAttrs: rec {
      version = "2026.08.19";
      src = prev.fetchFromGitHub {
        owner = "yt-dlp";
        repo = "yt-dlp";
        rev = version;
        hash = "sha256-BM5ZeGTmHq+1xH6G/zsuCtjLgYgfRA11ya0zIHK5p4g=";
      };
    });
  };
}
