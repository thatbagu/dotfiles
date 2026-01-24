{ lib, config, pkgs, ... }: {
  options = {
    arduino-nvim.enable = lib.mkEnableOption "Enable arduino-nvim module";
  };

  config = lib.mkIf config.arduino-nvim.enable {
    # Add the Arduino-Nvim plugin from GitHub
    extraPlugins = with pkgs.vimPlugins; [
      telescope-nvim
      nvim-lspconfig
      (pkgs.vimUtils.buildVimPlugin {
        name = "Arduino-Nvim";
        src = pkgs.fetchFromGitHub {
          owner = "yuukiflow";
          repo = "Arduino-Nvim";
          rev = "60e7ed08ca2bcf0cd357efb0aa74ae3dd528a83a";
          sha256 = "sha256-pQk5bks0oBywnzZcMaime4J3mjpOaG/OUTBv0gVd/gU=";
        };
      })
    ];

    # Set up Arduino filetype detection and auto-load
    extraConfigLua = ''
      -- Detect .ino files as arduino filetype
      vim.api.nvim_create_autocmd({"BufRead", "BufNewFile"}, {
        pattern = "*.ino",
        callback = function()
          vim.bo.filetype = "arduino"
        end,
      })

      -- Load Arduino plugin for .ino files
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "arduino",
        callback = function()
          require("Arduino-Nvim")
        end,
      })
    '';

    # Arduino keymaps (all prefixed with <Leader>a)
    keymaps = [
      {
        mode = "n";
        key = "<leader>ac";
        action = "<cmd>InoCheck<cr>";
        options = {
          desc = "Arduino: Compile and verify sketch";
          silent = true;
        };
      }
      {
        mode = "n";
        key = "<leader>au";
        action = "<cmd>InoUpload<cr>";
        options = {
          desc = "Arduino: Upload sketch to board";
          silent = true;
        };
      }
      {
        mode = "n";
        key = "<leader>ar";
        action = "<cmd>InoUploadReset<cr>";
        options = {
          desc = "Arduino: Upload with manual reset (UNO R4 WiFi)";
          silent = true;
        };
      }
      {
        mode = "n";
        key = "<leader>am";
        action = "<cmd>InoMonitor<cr>";
        options = {
          desc = "Arduino: Open serial monitor";
          silent = true;
        };
      }
      {
        mode = "n";
        key = "<leader>as";
        action = "<cmd>InoStatus<cr>";
        options = {
          desc = "Arduino: Display board and port status";
          silent = true;
        };
      }
      {
        mode = "n";
        key = "<leader>al";
        action = "<cmd>InoLib<cr>";
        options = {
          desc = "Arduino: Open library manager";
          silent = true;
        };
      }
      {
        mode = "n";
        key = "<leader>ag";
        action = "<cmd>InoGUI<cr>";
        options = {
          desc = "Arduino: Open GUI for board and port selection";
          silent = true;
        };
      }
      {
        mode = "n";
        key = "<leader>ap";
        action = "<cmd>InoSelectPort<cr>";
        options = {
          desc = "Arduino: Select Arduino port";
          silent = true;
        };
      }
      {
        mode = "n";
        key = "<leader>ab";
        action = "<cmd>InoSelectBoard<cr>";
        options = {
          desc = "Arduino: Select Arduino board";
          silent = true;
        };
      }
    ];
  };
}
