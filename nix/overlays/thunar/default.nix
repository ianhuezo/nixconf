final: prev: {
  thunar = prev.xfce.thunar.overrideAttrs (oldAttrs: rec {
    patches = (oldAttrs.patches or []) ++ [
      ./pipe.patch
    ];
  });
}

