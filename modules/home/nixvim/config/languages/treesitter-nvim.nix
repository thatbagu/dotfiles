# Complete treesitter configuration with all parsers
# Replace modules/home/nixvim/config/languages/treesitter-nvim.nix

{ lib, config, pkgs, ... }: {
  options = {
    treesitter-nvim.enable = lib.mkEnableOption "Enable treesitter-nvim module";
  };
  config = lib.mkIf config.treesitter-nvim.enable {
    plugins.treesitter = {
      enable = true;

      # Install parsers through Nix - this is the nixvim way
      grammarPackages = with pkgs.vimPlugins.nvim-treesitter.builtGrammars; [
        bash
        fish
        go
        gomod
        gowork
        json
        lua
        luadoc
        luap
        nix
        rust
        markdown
        markdown_inline
        python
        query
        regex
        terraform
        hcl
        vim
        vimdoc
        toml
        yaml
        javascript
        typescript
        html
        css
        sql
        dockerfile
        gitignore
        gitcommit
        diff
        comment
      ];

      settings = {
        highlight = {
          enable = true;
          additional_vim_regex_highlighting = false;
        };
        indent = { enable = true; };
        autopairs = { enable = true; };
        # Enable treesitter folding for supported languages
        folding = { enable = true; };

        # Don't use ensure_installed with nixvim - use grammarPackages instead
        # ensure_installed = []; 

        # Disable runtime installation since we're using Nix
        auto_install = false;
        sync_install = false;

        incremental_selection = {
          enable = true;
          keymaps = {
            init_selection = "<C-space>";
            node_incremental = "<C-space>";
            scope_incremental = false;
            node_decremental = "<bs>";
          };
        };
      };
      nixvimInjections = true;
    };

    extraConfigLua = ''
      -- Ensure treesitter doesn't try to install anything at runtime
      local ts_install = require('nvim-treesitter.install')

      -- Override installation functions
      local original_install = ts_install.install
      ts_install.install = function(...)
        print("Treesitter parsers are managed by Nix. No runtime installation needed.")
      end

      local original_update = ts_install.update
      ts_install.update = function(...)
        print("Treesitter parsers are managed by Nix. Update through nixos-rebuild.")
      end

      -- Disable the installation prompt
      ts_install.prefer_git = false
      ts_install.compilers = {}

      -- Fish shell support
      vim.api.nvim_create_autocmd({"BufRead", "BufNewFile"}, {
        pattern = "*.fish",
        callback = function()
          vim.bo.filetype = "fish"
        end
      })
    '';

    plugins.treesitter-textobjects = {
      enable = true;
      select = {
        enable = true;
        lookahead = true;
        keymaps = {
          "aa" = "@parameter.outer";
          "ia" = "@parameter.inner";
          "af" = "@function.outer";
          "if" = "@function.inner";
          "ac" = "@class.outer";
          "ic" = "@class.inner";
          "ii" = "@conditional.inner";
          "ai" = "@conditional.outer";
          "il" = "@loop.inner";
          "al" = "@loop.outer";
          "at" = "@comment.outer";
        };
      };
      move = {
        enable = true;
        gotoNextStart = {
          "]m" = "@function.outer";
          "]]" = "@class.outer";
        };
        gotoNextEnd = {
          "]M" = "@function.outer";
          "][" = "@class.outer";
        };
        gotoPreviousStart = {
          "[m" = "@function.outer";
          "[[" = "@class.outer";
        };
        gotoPreviousEnd = {
          "[M" = "@function.outer";
          "[]" = "@class.outer";
        };
      };
      swap = {
        enable = true;
        swapNext = { "<leader>a" = "@parameters.inner"; };
        swapPrevious = { "<leader>A" = "@parameter.outer"; };
      };
    };

    plugins.ts-autotag = { enable = true; };

    plugins.treesitter-context = { enable = true; };

    plugins.ts-context-commentstring = {
      enable = true;
      disableAutoInitialization = false;
    };
  };
}
