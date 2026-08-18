{
  lib,
  stdenv,
  fetchurl,
  makeWrapper,
  autoPatchelfHook,
  bubblewrap,
  procps,
  socat,
  git,
  ripgrep,
}:
stdenv.mkDerivation rec {
  pname = "oh-my-pi";
  version = "17.3.5";

  # Upstream ships a bare Bun-compiled executable, not an archive, so this is
  # fetchurl rather than fetchzip as in pi-coding-agent.
  src = fetchurl {
    url = "https://github.com/can1357/oh-my-pi/releases/download/v${version}/omp-linux-x64";
    hash = "sha256-YFtKijoTdImpHVnnAoxB86/yAWnzUpArQQifv9+KJTw=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
  ];

  buildInputs = [
    stdenv.cc.cc.lib
    procps
    bubblewrap
    socat
  ];

  dontBuild = true;
  dontConfigure = true;
  dontUnpack = true;
  # Bun bundles its JS payload after the ELF image; stripping discards it.
  dontStrip = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 $src $out/bin/omp
    runHook postInstall
  '';

  postFixup = ''
    wrapProgram $out/bin/omp \
      --prefix PATH : ${
        lib.makeBinPath [
          procps
          bubblewrap
          socat
          git
          ripgrep
        ]
      }
  '';

  meta = with lib; {
    description = "Terminal coding agent with LSP, DAP and role-based model routing (fork of pi)";
    homepage = "https://github.com/can1357/oh-my-pi";
    license = licenses.mit;
    maintainers = [ ];
    mainProgram = "omp";
    platforms = [ "x86_64-linux" ];
  };
}
