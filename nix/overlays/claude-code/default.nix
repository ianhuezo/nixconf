self: super: {
  claude-code = super.claude-code.overrideAttrs (oldAttrs: rec {
    version = "2.0.17";

    src = super.fetchzip {
      url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
      hash = "sha256-uQ+iosjjs6dUT8MtnFwubJqp85pBtBYkmIXTlRGufQw=";
    };

    npmDepsHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  });
}
