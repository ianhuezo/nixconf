final: prev: {
  vesktop = prev.vesktop.overrideAttrs (oldAttrs: {
    patches = (oldAttrs.patches or [ ]) ++ [
      ./frieren-dance.patch
    ];

    postPatch = ''
      cp ${../../../dotfiles/assets/frieren/frieren-dance.webp} static/splash.webp
    '';
  });
}
