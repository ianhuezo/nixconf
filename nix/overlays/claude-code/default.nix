self: super: {
  claude-code = super.buildNpmPackage rec {
    pname = "claude-code";
    version = "2.1.81";

    src = super.fetchzip {
      url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
      hash = "sha256-WT+fj9H/5hlr/U8MygiIdE2QZ32kRz6wTjYEABtmBPU=";
    };

    npmDepsHash = "sha256-x8Y1vODjATE6F6r0GhK427J0h2Et7bsqKoDcWaNO+IM=";

    strictDeps = true;

    postPatch = ''
      cp ${./package-lock.json} package-lock.json
      substituteInPlace cli.js \
        --replace-fail '#!/bin/sh' '#!/usr/bin/env sh'
    '';

    dontNpmBuild = true;

    env.AUTHORIZED = "1";

    postInstall = ''
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
    };
  };
}
