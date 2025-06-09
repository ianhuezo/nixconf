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
      type = types.attrs; # nix-colors uses an attrset for its schemes
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
        {
          mode = "n";
          key = "<leader>q"; # or any key combination you prefer
          action = ":bd<CR>";
          options = {
            desc = "Close current buffer";
            silent = true;
          };
        }
	{
	  mode = "n";
	  key = "<leader>e";
	  action = "<cmd>lua vim.diagnostic.open_float()<cr>";
	  options = {
	      desc = "Open diagnostic window";
	      silent = true;
	  };
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
      lsp-format = {
        enable = true;
        lspServersToEnable = "all";
      };
      lsp.keymaps.lspBuf = {
        "gd" = "definition";
        # Go-to-references
        "gr" = "references";
        # Hover documentation
        "K" = "hover";
        # Go to type definition
        "gy" = "type_definition";
        # Go to implementation
        "gi" = "implementation";
        # Rename symbol
        "<leader>rn" = "rename";
        # Show code actions
        "<leader>ca" = "code_action";
        # Show signature help
        "<C-k>" = "signature_help";
      };
      none-ls = {
        enable = true;
        enableLspFormat = true;
      };
      lsp.servers.typos_lsp.enable = true;
      typescript-tools = {
        enable = false;
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
      lsp.servers.qmlls = {
        enable = true;
        cmd = [
          "${pkgs.qt6.qtdeclarative}/bin/qmlls"
          "-I"
          "${inputs.quickshell.packages.${pkgs.system}.default}/lib/qt-6/qml"
          "-I"
          "${pkgs.qt6.qtdeclarative}/${pkgs.qt6.qtbase.qtQmlPrefix}"
        ];
        filetypes = [ "qml" ];
        autostart = true;
        settings = {
          # Optional: Configure LSP behavior
          qml.formatOnSave = true;
        };
      };

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

      luasnip.enable = true;
      cmp = {
        enable = true;
        autoEnableSources = true;
        settings = {
          sources = [
            { name = "nvim_lsp"; }
            { name = "buffer"; }
            { name = "path"; }
            { name = "treesitter"; }
            { name = "luasnip"; }
          ];
          mapping = {
            "<C-y>" = "cmp.mapping.confirm({ select = true })";
            "<C-n>" = "cmp.mapping.select_next_item()";
            "<C-p>" = "cmp.mapping.select_prev_item()";
            "<C-Space>" = "cmp.mapping.complete()";
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
            "*.lock"
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
      avante = {
        enable = false;
        settings = {
          claude = {
            endpoint = "https://api.anthropic.com";
            max_tokens = 4096;
            model = "claude-3-7-sonnet-20250219";
            temperature = 0;
          };
          diff = {
            autojump = true;
            debug = false;
            list_opener = "copen";
          };
          highlights = {
            diff = {
              current = "DiffText";
              incoming = "DiffAdd";
            };
          };
          hints = {
            enabled = true;
          };
          mappings = {
            diff = {
              both = "cb";
              next = "]x";
              none = "c0";
              ours = "co";
              prev = "[x";
              theirs = "ct";
            };
          };
          provider = "claude";
          windows = {
            sidebar_header = {
              align = "center";
              rounded = true;
            };
            width = 30;
            wrap = true;
          };
        };
      };
    };
  };

}
