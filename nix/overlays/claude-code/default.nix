self: super: {
  claude-code = super.buildNpmPackage rec {
    pname = "claude-code";
    version = "2.1.112";

    src = super.fetchzip {
      url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
      hash = "sha256-SJJqU7XHbu9IRGPMJNUg6oaMZiQUKqJhI2wm7BnR1gs=";
    };

    npmDepsHash = "sha256-bdkej9Z41GLew9wi1zdNX+Asauki3nT1+SHmBmaUIBU=";

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
