final: prev: {
  vesktop = prev.vesktop.overrideAttrs (oldAttrs: {
    postPatch = ''
      cp ${../../../dotfiles/assets/frieren/frieren-dance.webp} static/splash.webp
    '';
  });
}
