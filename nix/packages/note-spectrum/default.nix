{ lib, rustPlatform }:

rustPlatform.buildRustPackage {
  pname = "note-spectrum";
  version = "0.1.0";

  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [
      ./Cargo.toml
      ./Cargo.lock
      ./src
    ];
  };

  cargoLock.lockFile = ./Cargo.lock;

  meta = {
    description = "Semitone-binned spectrum of the default sink monitor for the quickshell visualizer";
    mainProgram = "note-spectrum";
  };
}
