{ lib
, rustPlatform
, fetchFromGitHub
}:

rustPlatform.buildRustPackage rec {
  pname = "quantette-cli";
  version = "0.5.1";

  src = fetchFromGitHub {
    owner = "IanManske";
    repo = "quantette";
    rev = "v${version}";
    hash = "sha256-XXbjCIWeCUmamD/cX3r9HlR139cI60okSgdYirItZ1Y=";
  };

  cargoHash = "sha256-ul+zDSezWU+oFRkoLgy63S6rdTm8RMV1BcW53xUd1gQ=";

  # Build the CLI example instead of the library
  buildPhase = ''
    runHook preBuild
    cargo build --release --example cli
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    cp target/release/examples/cli $out/bin/quantette-cli
    runHook postInstall
  '';

  meta = with lib; {
    description = "Fast and high quality image quantization CLI using Wu's algorithm";
    homepage = "https://github.com/IanManske/quantette";
    license = with licenses; [ mit asl20 ];
    maintainers = [ ];
    mainProgram = "quantette-cli";
  };
}
