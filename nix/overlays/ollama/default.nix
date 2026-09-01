final: prev:
let
  # nixpkgs is pinned well behind ollama here (0.18.2, from the 2026-03-28
  # lock). Qwen3.8 support landed upstream in 0.32.12; on an older engine
  # `ollama pull qwen3.8:27b` succeeds and then the load fails on the unknown
  # architecture, so the model is unusable without this bump. 0.32.13-0.32.15
  # followed with qwen3.8 developer-instruction and system-message fixes, which
  # is why this tracks 0.33.x rather than the bare 0.32.12 floor.
  #
  # Drop this overlay once the nixpkgs lock moves past 0.32.15.
  #
  # ollama-cuda is bumped explicitly rather than relying on it inheriting from
  # `ollama`: it is defined as `ollama.override { acceleration = "cuda"; }`, and
  # `.override` on an `overrideAttrs` result re-enters the original function, so
  # the version bump would be silently dropped.
  bump =
    drv:
    drv.overrideAttrs (oldAttrs: {
      version = "0.33.2";

      src = prev.fetchFromGitHub {
        owner = "ollama";
        repo = "ollama";
        tag = "v0.33.2";
        hash = "sha256-jzhzMkEC/X4AyLOcBB8lAPcef9B+pmM+WhvDgsd6D2E=";
      };

      vendorHash = "sha256-HMwoaFBMbpoy8f0I+O+i7kIa9BslLu3FcVWeaIOkpvs=";
    });
in
{
  ollama = bump prev.ollama;
  ollama-cuda = bump prev.ollama-cuda;
}
