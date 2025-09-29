{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.modules.hyprlock;
in
{
  options.modules.hyprlock = {
    enable = mkEnableOption "Enable hyprlock config for hyprland";
    colorScheme = mkOption {
      type = types.attrs;
      default = null;
      description = "base16 color scheme input";
    };
  };
  config = mkIf cfg.enable {
    #why does home manager not just install the package normally... I can just configure it myself...  Maybe TODO: get rid of hm implementation
    programs.hyprlock = {
      enable = true;
      extraConfig = ''
              # BACKGROUND
              background {
                  monitor =
                  path = ${config.home.homeDirectory}/Pictures/frieren.png
                  blur_size = 0
                  blur_passes = 1
                  noise = 0.0117
                  contrast = 1.300
                  brightness = 0.600
                  vibrancy = 0.2100
                  vibrancy_darkness = 0.0
              }

              # GENERAL
              general {
                  no_fade_in = false
                  grace = 0
                  disable_loading_bar = true
              }

              # INPUT FIELD
              input-field {
                  monitor =
                  size = 250, 50
                  outline_thickness = 3
                  dots_size = 0.26 # Scale of input-field height, 0.2 - 0.8
                  dots_spacing = 0.64 # Scale of dots' absolute size, 0.0 - 1.0
                  dots_center = true
                  outer_color = rgba(0, 0, 0, 0)
                  inner_color = rgba(0, 0, 0, 0.5)
                  font_color = rgb(200, 200, 200)
                  fade_on_empty = true
                  placeholder_text = <i><span foreground="##cdd6f4">Password...</span></i>
                  hide_input = false
                  position = 0, 80
                  halign = center
                  valign = bottom
              }

              # TIME
              label {
                  monitor =
                  text = cmd[update:1000] echo "<b><big> $(date +"%-H:%M:%S") </big></b>"
                  color = rgba(255, 255, 255, 0.6)
                  font_size = 100
                  font_family = JetBrains Mono Nerd Font
                  position = 0, 16
                  halign = center
                  valign = center
              }
              # DATE
              label {
                monitor =
                text = cmd[update:18000000] echo "<b> $(date + "%A, %-d %B %Y") </b>"
                color = rgba(255,255,255,0.6)
                font_size = 36
                font_family = JetBrains Mono Nerd Font

                position = 0, -46
                halign = center
                valign = center
              }

              # USER
              label {
                  monitor =
                  text = Greetings, Ian 
                  color = rgba(255, 255, 255, 0.8)
                  font_size = 24
                  font_family = JetBrains Mono Nerd Font Mono
                  position = 0, 30
        	        shadow_passes = 1
        	        shadow_boost = 1.2
        	        shadow_size = 3
        	        shadow_color = rgb(#${config.colorScheme.palette.base00})
                  halign = center
                  valign = bottom
              }
      '';
    };

  };
}
