final: prev: {
  tela-icon-theme = prev.tela-icon-theme.overrideAttrs (old: {
    postInstall = ''
      # Copies 24 as 32 for all Tela variants and adds viewbox for scaling
      ${old.postInstall or ""}
                
      cd $out/share/icons
      for theme in Tela-dark Tela-light; do
        if [ -d "$theme/24" ]; then
          # Ensure 32 directory structure exists
          mkdir -p "$theme/32"
          
          # For each subdirectory in 24
          for subdir in "$theme/24"/*; do
            if [ -d "$subdir" ]; then
              subdirname=$(basename "$subdir")
              mkdir -p "$theme/32/$subdirname"
              
              # For each icon in 24/subdir
              for icon in "$subdir"/*; do
                if [ -f "$icon" ]; then
                  iconname=$(basename "$icon")
                  # Only create copy if it doesn't exist in 32
                  if [ ! -e "$theme/32/$subdirname/$iconname" ]; then
                    ${prev.gnused}/bin/sed 's/width="24" height="24"/width="32" height="32" viewBox="0 0 24 24"/g' "$icon" > "$theme/32/$subdirname/$iconname"
                  fi
                fi
              done
            fi
          done
        fi
      done
    '';
  });
}
