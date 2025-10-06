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
  # Helper function to ensure color has # prefix
  addHashPrefix =
    color:
    let
      # Increment the last hex digit by 1
      chars = lib.stringToCharacters color;
      lastChar = lib.last chars;
      restChars = lib.init chars;

      # Increment logic for hex digits
      incrementedLast =
        if lastChar == "F" || lastChar == "f" then
          "0"
        else if lastChar == "9" then
          "A"
        else if lastChar == "E" || lastChar == "e" then
          "F"
        else if lastChar == "D" || lastChar == "d" then
          "E"
        else if lastChar == "C" || lastChar == "c" then
          "D"
        else if lastChar == "B" || lastChar == "b" then
          "C"
        else if lastChar == "A" || lastChar == "a" then
          "B"
        else if lastChar == "8" then
          "9"
        else if lastChar == "7" then
          "8"
        else if lastChar == "6" then
          "7"
        else if lastChar == "5" then
          "6"
        else if lastChar == "4" then
          "5"
        else if lastChar == "3" then
          "4"
        else if lastChar == "2" then
          "3"
        else if lastChar == "1" then
          "2"
        else
          "1"; # lastChar == "0"

      newColor = lib.concatStrings (restChars ++ [ incrementedLast ]);
    in
    "#${newColor}";
  base16Colors = builtins.mapAttrs (name: value: addHashPrefix value) cfg.colorScheme.palette;
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
    home.packages = [
      inputs.nixd.packages.${pkgs.system}.default
    ];
    programs.nixvim = {
      enable = true;
      globals.mapleader = " ";
      opts = {
        number = true; # Show line numbers
        relativenumber = true; # Show relative line numbers
        shiftwidth = 2; # Tab width should be 2
        cursorline = true;
      };
      colorschemes.base16 = {
        enable = true;
        colorscheme = base16Colors;
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
    programs.nixvim.keymaps = [
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
        action = ":bd!<CR>";
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

    programs.nixvim.extraConfigLua = ''

      vim.api.nvim_set_hl(0, "CursorLineNr", { fg = "${base16Colors.base09}", bold = true })

      vim.api.nvim_set_hl(0, "TelescopeBorder", { fg = "${base16Colors.base0B}", bg = "${base16Colors.base00}" })

      vim.api.nvim_set_hl(0, "TelescopePromptNormal", { bg = "${base16Colors.base01}" })
      vim.api.nvim_set_hl(0, "TelescopePromptBorder", { fg = "${base16Colors.base0B}", bg = "${base16Colors.base01}" })
      vim.api.nvim_set_hl(0, "TelescopePromptTitle", { fg = "${base16Colors.base00}", bg = "${base16Colors.base0B}", bold = true })

      vim.api.nvim_set_hl(0, "TelescopeResultsNormal", { bg = "${base16Colors.base00}" })
      vim.api.nvim_set_hl(0, "TelescopeResultsBorder", { fg = "${base16Colors.base0C}", bg = "${base16Colors.base00}" })
      vim.api.nvim_set_hl(0, "TelescopeResultsTitle", { fg = "${base16Colors.base00}", bg = "${base16Colors.base0C}", bold = true })

      -- Preview window
      vim.api.nvim_set_hl(0, "TelescopePreviewNormal", { bg = "${base16Colors.base01}" })
      vim.api.nvim_set_hl(0, "TelescopePreviewBorder", { fg = "${base16Colors.base0E}", bg = "${base16Colors.base01}" })
      vim.api.nvim_set_hl(0, "TelescopePreviewTitle", { fg = "${base16Colors.base00}", bg = "${base16Colors.base0E}", bold = true })

      -- Selection highlight
      vim.api.nvim_set_hl(0, "TelescopeSelection", { fg = "${base16Colors.base05}", bg = "${base16Colors.base02}", bold = true })

      -- Selection highlight
      vim.api.nvim_set_hl(0, "TelescopeSelection", { fg = "${base16Colors.base05}", bg = "${base16Colors.base02}", bold = true })

      -- Matched text highlighting
      vim.api.nvim_set_hl(0, "TelescopeMatching", { fg = "${base16Colors.base0B}", bold = true })


      vim.api.nvim_set_hl(0, "@function", { fg = "${base16Colors.base0D}", bold = true })
      vim.api.nvim_set_hl(0, "@method", { fg = "${base16Colors.base0D}", italic = true })
      vim.api.nvim_set_hl(0, "@variable", { fg = "${base16Colors.base05}" })
      vim.api.nvim_set_hl(0, "@property", { fg = "${base16Colors.base0E}" })
    '';

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
      colorizer.enable = true;
      colorizer.settings = {
        RRGGBBAA = true;
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

      lsp.servers.nixd = {
        enable = true;
        settings = {
          nixpkgs.expr = "import (builtins.getFlake \"${inputs.self}\").inputs.nixpkgs {}";
          options = {
            nixos = {
              expr = "(builtins.getFlake \"${inputs.self}\").nixosConfigurations.joyboy.options";
            };
            home_manager = {
              expr = "(builtins.getFlake \"${inputs.self}\").homeConfigurations.ianh.options";
            };
          };
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
        enable = true;
        settings = {
          formatters_by_ft = {
            qml = [ ];
            "*" = [ "treefmt" ];
          };
          formatters = {
            treefmt = {
              command = "treefmt";
              args = [ "$FILENAME" ];
              stdin = false; # Don't use stdin, let treefmt read the file directly
            };
          };
          format_on_save = {
            timeout_ms = 500;
            lsp_fallback = true;
          };
        };
      };
      presence-nvim = {
        enable = true;
        debounceTimeout = 30;
        blacklist = [
          "^%.env"
        ];
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
