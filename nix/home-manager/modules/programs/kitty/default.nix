{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.modules.kitty;
in
{
  options.modules.kitty = {
    enable = mkEnableOption "Kitty terminal emulator";

    colorScheme = mkOption {
      type = types.attrs;
      description = "Color scheme configuration with palette";
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      kitty
      maple-mono.NF-CN
    ];
    # ++ builtins.filter lib.attrsets.isDerivation (builtins.attrValues pkgs.maple-mono);

    programs.kitty = {
      enable = true;
      extraConfig = ''
        font_family Maple Mono NF CN
        bold_font Maple Mono NF CN
        bold_italic_font Maple Mono NF CN
        font_size 12.0
        map ctrl+shift+enter no_op
        map ctrl+shift+[ no_op
        map ctrl+shift+] no_op
        background_opacity 0.85
        foreground #${cfg.colorScheme.palette.base05} 
        background #${cfg.colorScheme.palette.base00} 
        # grayish
        color0 #${cfg.colorScheme.palette.base03} 
        color8 #${cfg.colorScheme.palette.base03} 
        # Salmon
        color1 #${cfg.colorScheme.palette.base08} 
        color9 #${cfg.colorScheme.palette.base08} 
        # Green
        color2  #${cfg.colorScheme.palette.base0C} 
        color10 #${cfg.colorScheme.palette.base0C} 
        # Yellow-brown
        color3  #${cfg.colorScheme.palette.base09} 
        color11 #${cfg.colorScheme.palette.base09} 
        # Blue
        color4  #${cfg.colorScheme.palette.base0D} 
        color12 #${cfg.colorScheme.palette.base0D}
        # Magenta
        color5  #${cfg.colorScheme.palette.base0E} 
        color13 #${cfg.colorScheme.palette.base0E}
        # Cyan
        color6  #${cfg.colorScheme.palette.base0C} 
        color14 #${cfg.colorScheme.palette.base0C} 
        # White
        color7  #${cfg.colorScheme.palette.base05} 
        color15 #${cfg.colorScheme.palette.base05} 
        # Cursor
        cursor #${cfg.colorScheme.palette.base05} 
        cursor_text_color #${cfg.colorScheme.palette.base00} 
        # Selection highlight
        selection_foreground none
        selection_background #${cfg.colorScheme.palette.base03}
        # The color for highlighting URLs on mouse-over
        url_color #${cfg.colorScheme.palette.base0B}
        # Window borders
        active_border_color #${cfg.colorScheme.palette.base0D}
        inactive_border_color #${cfg.colorScheme.palette.base00}
        bell_border_color #${cfg.colorScheme.palette.base09}
        # Tab bar
        tab_bar_style fade
        tab_fade 1
        active_tab_foreground   #${cfg.colorScheme.palette.base0D}
        active_tab_background   #${cfg.colorScheme.palette.base00}
        active_tab_font_style   bold
        inactive_tab_foreground #${cfg.colorScheme.palette.base04}
        inactive_tab_background #${cfg.colorScheme.palette.base00}
        inactive_tab_font_style bold
        tab_bar_background #${cfg.colorScheme.palette.base00}
      '';
    };
  };
}
