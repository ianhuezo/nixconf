self: super: {
  claude-code = super.stdenv.mkDerivation rec {
    pname = "claude-code";
    version = "2.1.162";

    src = super.fetchzip {
      url = "https://registry.npmjs.org/@anthropic-ai/claude-code-linux-x64/-/claude-code-linux-x64-${version}.tgz";
      hash = "sha256-7GQR+4jzoF042T62HXTGwLys2h2/lCzYZvCk6FuNXBE=";
    };

    nativeBuildInputs = with super; [ autoPatchelfHook makeWrapper ];

    buildInputs = with super; [ stdenv.cc.cc.lib ];

    dontBuild = true;
    dontConfigure = true;
    dontStrip = true;

    installPhase = ''
      runHook preInstall
      install -Dm755 claude $out/bin/claude
      runHook postInstall
    '';

    postFixup = ''
      wrapProgram $out/bin/claude \
        --set DISABLE_AUTOUPDATER 1 \
        --set DISABLE_INSTALLATION_CHECKS 1 \
        --unset DEV \
        --prefix PATH : ${super.lib.makeBinPath (with super; [ procps bubblewrap socat ])}
    '';

    meta = with super.lib; {
      description = "An agentic coding tool that lives in your terminal";
      homepage = "https://github.com/anthropics/claude-code";
      license = licenses.unfree;
      maintainers = [ ];
      mainProgram = "claude";
      platforms = [ "x86_64-linux" ];
    };
  };
}
