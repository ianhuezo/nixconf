final: prev: {
  thunar = prev.thunar.overrideAttrs (oldAttrs: {
    patches = (oldAttrs.patches or [ ]) ++ [
      ./pipe.patch
    ];
  });
}
