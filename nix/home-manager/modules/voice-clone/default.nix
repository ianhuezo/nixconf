{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.modules.voice-clone;
in
{
  options.modules.voice-clone = {
    enable = mkEnableOption "croak real-time voice conversion build environment";
  };

  config = mkIf cfg.enable {
    # Native build inputs for the `croak` crate.
    #   - alsa-lib : cpal's Linux audio backend links against ALSA; the build
    #                fails without `alsa.pc` reachable via pkg-config.
    #   - pkg-config : lets the alsa-sys build script discover alsa-lib.
    #   - onnxruntime : dynamically loaded by the `ort-backend` feature
    #                   (see ORT_DYLIB_PATH below). Harmless when unused.
    home.packages = with pkgs; [
      pkg-config
      alsa-lib
      onnxruntime
    ];

    home.sessionVariables = {
      # alsa-sys runs `pkg-config --libs --cflags alsa`; point it at the
      # alsa-lib dev output that ships `alsa.pc`.
      PKG_CONFIG_PATH = "${pkgs.alsa-lib.dev}/lib/pkgconfig";
      # The `ort` crate loads ONNX Runtime at runtime (load-dynamic). Give it
      # the shared library so `--features ort-backend` works out of the box.
      ORT_DYLIB_PATH = "${pkgs.onnxruntime}/lib/libonnxruntime.so";
    };
  };
}
