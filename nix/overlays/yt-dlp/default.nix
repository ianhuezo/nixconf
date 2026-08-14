final: prev: {
  python3Packages = prev.python3Packages // {
    # nixpkgs lags yt-dlp badly; a stale yt-dlp gets HTTP 403 on YouTube audio
    # downloads once SABR forces the android_vr fallback. Keep patches/postPatch
    # from the base package -- postPatch is what wires deno in for JS challenges.
    yt-dlp = prev.python3Packages.yt-dlp.overrideAttrs (oldAttrs: rec {
      version = "2026.07.04";
      src = prev.fetchFromGitHub {
        owner = "yt-dlp";
        repo = "yt-dlp";
        rev = version;
        hash = "sha256-+oHcVylLXFJTRR6jXF6IXvgntXJz0tRdtnwTruRPkoc=";
      };
    });
  };
}
