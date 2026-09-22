{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
with lib;
let
  cfg = config.modules.stocks;

  stocksPkgs = import inputs.nixpkgs {
    inherit (pkgs.stdenv.hostPlatform) system;
    config = {
      allowUnfree = true;
      cudaSupport = cfg.cuda;
    };
    overlays = optional cfg.cuda (
      final: prev: {
        cudaPackages = final.${cfg.cudaPackages};
        suitesparse = prev.suitesparse.override { enableCuda = false; };
      }
    );
  };

  python = stocksPkgs.python312.override {
    packageOverrides = pyfinal: pyprev: {
      torch = (if cfg.cuda then pyprev.torch-bin else pyprev.torch).overridePythonAttrs (_: {
        dontCheckRuntimeDeps = true;
      });

      curl-cffi = pyprev.curl-cffi.overridePythonAttrs (_: {
        doCheck = false;
      });
      fastapi = pyprev.fastapi.overridePythonAttrs (_: {
        doCheck = false;
      });
      websockets = pyprev.websockets.overridePythonAttrs (_: {
        doCheck = false;
      });
      tqdm = pyprev.tqdm.overridePythonAttrs (_: {
        doCheck = false;
      });
      narwhals = pyprev.narwhals.overridePythonAttrs (_: {
        doCheck = false;
      });

      optuna = pyprev.optuna.overridePythonAttrs (_: {
        doCheck = false;
      });

      xgboost = pyfinal.buildPythonPackage rec {
        pname = "xgboost";
        version = "3.4.1";
        format = "wheel";
        src = stocksPkgs.fetchPypi {
          inherit pname version format;
          dist = "py3";
          python = "py3";
          abi = "none";
          platform = "manylinux_2_28_x86_64";
          hash = "sha256-at8q+jltoq6O0wKVtQuZ1HEu7ZpuDObP4GkpDkM15R8=";
        };
        nativeBuildInputs = [
          stocksPkgs.autoPatchelfHook
        ]
        ++ optional cfg.cuda stocksPkgs.autoAddDriverRunpath;
        buildInputs = [ stocksPkgs.stdenv.cc.cc.lib ];
        propagatedBuildInputs = with pyfinal; [
          numpy
          scipy
        ];
        dontCheckRuntimeDeps = true;
        pythonImportsCheck = [ "xgboost" ];
      };

      alpaca-py = pyfinal.buildPythonPackage rec {
        pname = "alpaca-py";
        version = "0.43.2";
        format = "pyproject";
        src = stocksPkgs.fetchPypi {
          pname = "alpaca_py";
          inherit version;
          sha256 = "sha256-4Dx4Ramsa1WBwx8Af+BnHwxTZTjxMOuEB4kKS6N+6GY=";
        };
        nativeBuildInputs = with pyfinal; [
          poetry-core
          poetry-dynamic-versioning
        ];
        propagatedBuildInputs = with pyfinal; [
          requests
          pydantic
          pandas
          msgpack
          websockets
          sseclient-py
        ];
        doCheck = false;
      };
    };
  };

  pythonEnv = python.withPackages (
    ps: with ps; [
      alpaca-py
      optuna
      numpy
      pandas
      scipy
      cvxpy
      requests
      websockets
      yfinance
      lxml
      scikit-learn
      hdbscan
      xgboost
      textual
      plotext
      torch
      python-dotenv
      pyyaml
      nltk
      transformers
      fastapi
      uvicorn
      pydantic
      pytest
      pytest-cov
      rich
      ruff
      pyarrow
      ipykernel
      pyvis
      numba
    ]
  );

  envVars = ''
    export TORCHINDUCTOR_COMPILE_THREADS=1
    export OMP_NUM_THREADS=1
    export MKL_NUM_THREADS=1
  '';

  stocks-python = stocksPkgs.writeShellScriptBin "stocks-python" ''
    ${envVars}
    exec ${pythonEnv}/bin/python "$@"
  '';

  stocks-shell = stocksPkgs.writeShellScriptBin "stocks-shell" ''
    ${envVars}
    export PATH="${pythonEnv}/bin:$PATH"
    exec "''${SHELL:-${stocksPkgs.bashInteractive}/bin/bash}" "$@"
  '';
in
{
  options.modules.stocks = {
    enable = mkEnableOption "alpaca trading bot python environment";

    cuda = mkOption {
      type = types.bool;
      default = true;
      description = "Build the environment against CUDA using torch-bin.";
    };

    cudaPackages = mkOption {
      type = types.str;
      default = "cudaPackages_13";
      description = "Nixpkgs CUDA package set to pin the environment to.";
    };

    jupyterKernel = mkOption {
      type = types.bool;
      default = true;
      description = "Register the environment as a jupyter kernel named stocks.";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [
      stocks-python
      stocks-shell
    ];

    home.file.".local/share/jupyter/kernels/stocks/kernel.json" = mkIf cfg.jupyterKernel {
      text = builtins.toJSON {
        argv = [
          "${pythonEnv}/bin/python"
          "-m"
          "ipykernel_launcher"
          "-f"
          "{connection_file}"
        ];
        display_name = "stocks (nix)";
        language = "python";
      };
    };
  };
}
