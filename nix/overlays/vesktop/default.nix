final: prev:
let
  newSrc = prev.fetchFromGitHub {
    owner = "Vencord";
    repo = "Vesktop";
    rev = "61ecf66936ed5069b661306781e396edf26b1e01";
    hash = "sha256-pNBiH6TsyBiw+QAgBwGZO8f+bnth6bl5WGc7rt4QTcI=";
  };
in
{
  vesktop = (prev.vesktop.override {
    electron_40 = prev.electron_41;
  }).overrideAttrs (oldAttrs: {
    version = "unstable-2026-05-26";

    src = newSrc;

    pnpmDeps = prev.fetchPnpmDeps {
      inherit (oldAttrs) pname;
      version = "unstable-2026-05-26";
      src = newSrc;
      pnpm = prev.pnpm_10_29_2;
      fetcherVersion = 2;
      hash = "sha256-AjZ1KicQTqmm83ADLqdEwX5VXNELWWRbE54I06iRZ1A=";
    };

    patches = (oldAttrs.patches or [ ]) ++ [
      ./frieren-dance.patch
    ];

    postPatch = ''
      cp ${../../../dotfiles/assets/frieren/frieren-dance.webp} static/splash.webp
    '';
  });
}
