{ pkgs }:

{
  kmeans-colors = pkgs.callPackage ./kmeans-colors { };
  quantette-cli = pkgs.callPackage ./quantette-cli { };
  pi-coding-agent = pkgs.callPackage ./pi-coding-agent { };
  oh-my-pi = pkgs.callPackage ./oh-my-pi { };
}
