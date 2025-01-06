{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

with lib;

let
  cfg = config.modules.neovim;
in
{
  imports = [
    inputs.nixvim.homeManagerModules.nixvim
  ];
  
  options.modules.neovim = {
    enable = mkEnableOption "neovim configuration";
    colorScheme = mkOption {
      type = types.attrs;  # nix-colors uses an attrset for its schemes
      default = null;
      description = "Color scheme from nix-colors";
    };
  };

  config = mkIf cfg.enable {
    programs.nixvim = {
      enable = true;
      globals.mapleader = " ";
      opts = {
        number = true; # Show line numbers
        relativenumber = true; # Show relative line numbers
        shiftwidth = 2; # Tab width should be 2
      };
      colorschemes.tokyonight = {
        enable = true;
        settings.style = "night";
        settings.on_highlights = ''
          	function(highlights, colors) 
                     highlights.LineNr = {
                       fg = "#${cfg.colorScheme.palette.base09}",
                     }
          	end
        '';
      };
      plugins.lualine.enable = true;
      plugins.web-devicons.enable = true;

      clipboard.register = "unnamedplus";
      clipboard.providers.wl-copy.enable = true;
      extraPackages = with pkgs; [
        ripgrep # for live_grep
        fd # for find_files
      ];
    };
    programs.nixvim.keymaps =
      [
        {
          mode = "n";
          key = "<S-l>"; # Shift + l
          action = ":BufferLineCycleNext<CR>";
          options.silent = true;
        }
        {
          mode = "n";
          key = "<S-h>"; # Shift + h
          action = ":BufferLineCyclePrev<CR>";
          options.silent = true;
        }
      ]
      ++ (builtins.concatLists (
        builtins.genList (
          i:
          let
            ws = i + 1;
          in
          [
            {
              mode = "n";
              key = "<leader>${toString ws}";
              action = ":BufferLineGoToBuffer ${toString ws}<CR>";
              options.silent = true;
            }
          ]
        ) 9
      ));

    programs.nixvim.plugins = {
      lsp.enable = true;
      # lsp.servers.qmlls.enable = true;
      typescript-tools = {
        enable = true;
        # settings.tsserverPlugins = [ "ags-ts" ];
      };
      lsp.servers.ts_ls.enable = true;
      lsp.servers.ts_ls.filetypes = [
        "javascript"
        "javascriptreact"
        "javascript.jsx"
        "typescript"
        "typescriptreact"
        "typescript.tsx"
        "vue"
      ];

      treesitter = {
        enable = true;
        settings = {
          auto_install = true;
          highlight = {
            enable = true;
            additional_vim_regex_highlighting = true;
          };
        };
      };
      cmp = {
        enable = true;
        settings = {
          snippet.expand = "function(args) require('luasnip').lsp_expand(args.body) end";
          window = {
            completion.__raw = "cmp.config.window.bordered";
            documentation.__raw = "cmp.config.window.bordered";
          };
        };
      };
      telescope = {
        enable = true;
        # Basic keymaps
        keymaps = {
          "<leader>ff" = "find_files";
          "<leader>fg" = "live_grep";
          "<leader>fb" = "buffers";
          "<leader>fh" = "help_tags";
        };

        # Optional: Configure telescope defaults
        settings.defaults = {
          file_ignore_patterns = [
            "node_modules"
            ".git"
            "target"
          ];
          # Set to false if you don't have ripgrep installed
          vimgrep_arguments = [
            "rg"
            "--color=never"
            "--no-heading"
            "--with-filename"
            "--line-number"
            "--column"
            "--smart-case"
          ];
        };
      };
      conform-nvim = {

      };
      bufferline = {
        enable = true;
        settings = {
          options = {
            numbers = "ordinal";
            diagnostics = "nvim_lsp";
            diagnostics_indicator = # Lua
              ''
                function(count, level, diagnostics_dict, context)
                  local s = ""
                  for e, n in pairs(diagnostics_dict) do
                    local sym = e == "error" and " "
                      or (e == "warning" and " " or "" )
                    if(sym ~= "") then
                      s = s .. " " .. n .. sym
                    end
                  end
                  return s
                end
              '';
            separator_style = "thin";
            show_buffer_close_icons = true;
            show_close_icon = true;
            persist_buffer_sort = true;
            show_tab_indicators = true;
          };
        };
      };
    };
  };

}
