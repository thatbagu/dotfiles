{ lib, config, pkgs, ... }: {
  options = {
    nvim-platformio.enable = lib.mkEnableOption "Enable nvim-platformio module";
  };

  config = lib.mkIf config.nvim-platformio.enable {
    # Add toggleterm as a dependency for nvim-platformio.lua
    plugins.toggleterm = {
      enable = true;
      settings = {
        direction = "horizontal";
        size = 20;
        open_mapping = "[[<c-\\>]]";
        hide_numbers = true;
        shade_terminals = true;
        start_in_insert = true;
        insert_mappings = true;
        terminal_mappings = true;
        persist_size = true;
        persist_mode = true;
        close_on_exit = true;
        shell = "vim.o.shell";
      };
    };

    # Add nvim-platformio.lua plugin from GitHub
    extraPlugins = with pkgs.vimPlugins; [
      telescope-nvim
      telescope-ui-select
      plenary-nvim
      which-key-nvim
      nvim-treesitter
      (pkgs.vimUtils.buildVimPlugin {
        name = "nvim-platformio.lua";
        src = pkgs.fetchFromGitHub {
          owner = "anurag3301";
          repo = "nvim-platformio.lua";
          rev = "95fb921677b4a738428da7d0d009eeab7a44c3ef";
          sha256 = "sha256-9j3YRCV3AGo2Nl8CsKzPQ0LN8z9SFmKRjurc4YNE2ag=";
        };
      })
    ];

    # Configure nvim-platformio.lua
    extraConfigLua = ''
      -- PlatformIO configuration
      vim.g.pioConfig = {
        lsp = 'clangd',           -- Use clangd for LSP
        clangd_source = 'ccls',   -- Use ccls compilation database
        menu_key = '<leader>\\',  -- Menu keybinding
        debug = false             -- Disable debug messages
      }

      -- Ensure the plugin is loaded
      require("nvim-platformio")
    '';

    # PlatformIO keymaps
    keymaps = [
      {
        mode = "n";
        key = "<leader>\\";
        action = "<cmd>lua require('nvim-platformio').toggle_menu()<cr>";
        options = {
          desc = "PlatformIO: Open menu";
          silent = true;
        };
      }
      {
        mode = "n";
        key = "<leader>pb";
        action = "<cmd>PlatformIOBuild<cr>";
        options = {
          desc = "PlatformIO: Build project";
          silent = true;
        };
      }
      {
        mode = "n";
        key = "<leader>pu";
        action = "<cmd>PlatformIOUpload<cr>";
        options = {
          desc = "PlatformIO: Upload to device";
          silent = true;
        };
      }
      {
        mode = "n";
        key = "<leader>pm";
        action = "<cmd>PlatformIOMonitor<cr>";
        options = {
          desc = "PlatformIO: Open serial monitor";
          silent = true;
        };
      }
      {
        mode = "n";
        key = "<leader>pc";
        action = "<cmd>PlatformIOClean<cr>";
        options = {
          desc = "PlatformIO: Clean project";
          silent = true;
        };
      }
    ];
  };
}
