{ lib
, rustPlatform
, fetchFromGitHub
}:

rustPlatform.buildRustPackage rec {
  pname = "kmeans-colors";
  version = "0.7.1";

  src = fetchFromGitHub {
    owner = "okaneco";
    repo = "kmeans-colors";
    rev = version;
    hash = "sha256-5jkgUUanJJmJwNbyCgYajqLRsd7beEX6ndSuYQETuV4=";
  };

  cargoHash = "sha256-ThS1NC7HwETY6vDRK21MWmkudMqFYPjEU+2NKn7adw8=";

  meta = with lib; {
    description = "Calculate the k average colors in an image using k-means clustering";
    homepage = "https://github.com/okaneco/kmeans-colors";
    license = licenses.mit;
    maintainers = [ ];
    mainProgram = "kmeans_colors";
  };
}
