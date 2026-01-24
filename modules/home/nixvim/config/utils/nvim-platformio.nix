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
    # Dependencies (telescope, plenary, which-key, treesitter) are already configured elsewhere
    extraPlugins = [
      (pkgs.vimUtils.buildVimPlugin rec {
        pname = "nvim-platformio-lua";
        version = "2024-11-06";
        src = pkgs.fetchFromGitHub {
          owner = "anurag3301";
          repo = "nvim-platformio.lua";
          rev = "95fb921677b4a738428da7d0d009eeab7a44c3ef";
          sha256 = "sha256-9j3YRCV3AGo2Nl8CsKzPQ0LN8z9SFmKRjurc4YNE2ag=";
        };
        # Skip neovim module checks - plugin requires platformio at runtime, not build time
        nvimSkipModule = [
          "platformio.boilerplate"
          "platformio"
          "platformio.piocmd"
          "platformio.piodebug"
          "platformio.pioinit"
          "platformio.piolib"
          "platformio.piolsp"
          "platformio.piolsserial"
          "platformio.piomenu"
          "platformio.piomon"
          "platformio.piorun"
          "platformio.utils"
          "minimal_config"
        ];
        meta.homepage = "https://github.com/anurag3301/nvim-platformio.lua";
      })
    ];

    # Configure nvim-platformio.lua
    extraConfigLua = ''
      -- PlatformIO configuration
      vim.g.pioConfig = {
        lsp = 'clangd',              -- Use clangd for LSP
        clangd_source = 'compiledb', -- Use compile_commands.json from PlatformIO
        menu_key = '<leader>\\',     -- Menu keybinding
        debug = false                -- Disable debug messages
      }

      -- Load the plugin with error handling
      local pok, platformio = pcall(require, 'platformio')
      if pok then
        platformio.setup(vim.g.pioConfig)
      end

      -- Disable clangd diagnostics for Arduino/PlatformIO files
      -- This prevents false errors while keeping autocomplete
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(args)
          local client = vim.lsp.get_client_by_id(args.data.client_id)
          if client and client.name == "clangd" then
            -- Check if we're in a PlatformIO project
            if vim.fn.filereadable(vim.fn.getcwd() .. "/platformio.ini") == 1 then
              -- Disable diagnostics for this buffer
              vim.diagnostic.disable(args.buf)
            end
          end
        end,
      })
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
