{ pkgs }:

{
  kmeans-colors = pkgs.callPackage ./kmeans-colors { };
  quantette-cli = pkgs.callPackage ./quantette-cli { };
}
