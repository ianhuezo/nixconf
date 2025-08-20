final: prev: {
  thunar = prev.thunar.overrideAttrs (oldAttrs: {
    patches = (oldAttrs.patches or []) ++ [
      # Path relative to your configuration directory
      ./pipe.patch
    ];
  });
}
