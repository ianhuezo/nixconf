{ lib
, python3
, fetchFromGitHub
, runCommand
}:

let
  graphifyy = python3.pkgs.buildPythonPackage rec {
    pname = "graphifyy";
    version = "0.7.6";
    pyproject = true;

    src = fetchFromGitHub {
      owner = "safishamsi";
      repo = "graphify";
      rev = "v${version}";
      hash = "sha256-x/dg81iU4bQhdne/oG1ywwc73/Odeq3EH9UT9ICBZ6Q=";
    };

    pythonRemoveDeps = [ "tree-sitter-objc" ];

    build-system = [ python3.pkgs.setuptools ];

    dependencies = with python3.pkgs; [
      networkx
      datasketch
      rapidfuzz
      tree-sitter
      tree-sitter-grammars.tree-sitter-python
      tree-sitter-grammars.tree-sitter-javascript
      tree-sitter-grammars.tree-sitter-typescript
      tree-sitter-grammars.tree-sitter-go
      tree-sitter-grammars.tree-sitter-rust
      tree-sitter-grammars.tree-sitter-java
      tree-sitter-grammars.tree-sitter-c
      tree-sitter-grammars.tree-sitter-cpp
      tree-sitter-grammars.tree-sitter-ruby
      tree-sitter-grammars.tree-sitter-c-sharp
      tree-sitter-grammars.tree-sitter-scala
      tree-sitter-grammars.tree-sitter-php
      tree-sitter-grammars.tree-sitter-kotlin
      tree-sitter-grammars.tree-sitter-swift
      tree-sitter-grammars.tree-sitter-lua
      tree-sitter-grammars.tree-sitter-zig
      tree-sitter-grammars.tree-sitter-powershell
      tree-sitter-grammars.tree-sitter-elixir
      tree-sitter-grammars.tree-sitter-julia
      tree-sitter-grammars.tree-sitter-verilog
      tree-sitter-grammars.tree-sitter-fortran
    ];

    pythonImportsCheck = [ "graphify" ];

    meta = with lib; {
      description = "Turn any folder of code, docs, papers, images, or tweets into a queryable knowledge graph";
      homepage = "https://github.com/safishamsi/graphify";
      license = licenses.mit;
      maintainers = [ ];
      mainProgram = "graphify";
    };
  };

  pythonEnv = python3.withPackages (ps: [ graphifyy ]);
in
runCommand "graphify-${graphifyy.version}"
{
  inherit (graphifyy) meta;
  passthru = { inherit graphifyy pythonEnv; };
} ''
  mkdir -p $out/bin
  ln -s ${pythonEnv}/bin/graphify $out/bin/graphify
  ln -s ${pythonEnv}/bin/python3  $out/bin/graphify-python
''
