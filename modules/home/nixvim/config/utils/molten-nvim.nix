{ lib, config, pkgs, ... }: {
  options = {
    molten-nvim.enable = lib.mkEnableOption "Enable molten-nvim module";
  };
  config = lib.mkIf config.molten-nvim.enable {
    # Use the built-in molten plugin in nixvim
    plugins.molten = {
      enable = true;
      # Avoid setting any options that might conflict
    };

    # Add the required Python packages (these don't conflict)
    extraPackages = with pkgs;
      [
        # Required Python packages
        (python3.withPackages (ps:
          with ps; [
            pynvim
            jupyter-client
            # Optional packages for enhanced functionality
            cairosvg
            pnglatex
            plotly
            pyperclip
            nbformat
            pillow
          ]))
      ];

    # Add keybindings (these don't conflict)
    keymaps = [
      {
        mode = "n";
        key = "<localleader>ji";
        action = ":MoltenInit<CR>";
        options = {
          silent = true;
          desc = "Initialize Molten";
        };
      }
      {
        mode = "n";
        key = "<localleader>je";
        action = ":MoltenEvaluateOperator<CR>";
        options = {
          silent = true;
          desc = "Run operator selection";
        };
      }
      {
        mode = "n";
        key = "<localleader>jl";
        action = ":MoltenEvaluateLine<CR>";
        options = {
          silent = true;
          desc = "Evaluate line";
        };
      }
      {
        mode = "n";
        key = "<localleader>jr";
        action = ":MoltenReevaluateCell<CR>";
        options = {
          silent = true;
          desc = "Re-evaluate cell";
        };
      }
      {
        mode = "v";
        key = "<localleader>j";
        action = ":<C-u>MoltenEvaluateVisual<CR>gv";
        options = {
          silent = true;
          desc = "Evaluate visual selection";
        };
      }
      {
        mode = "n";
        key = "<localleader>jd";
        action = ":MoltenDelete<CR>";
        options = {
          silent = true;
          desc = "Delete cell";
        };
      }
      {
        mode = "n";
        key = "<localleader>jh";
        action = ":MoltenHideOutput<CR>";
        options = {
          silent = true;
          desc = "Hide output";
        };
      }
      {
        mode = "n";
        key = "<localleader>js";
        action = ":noautocmd MoltenEnterOutput<CR>";
        options = {
          silent = true;
          desc = "Show/enter output";
        };
      }
      # Additional useful keybindings
      {
        mode = "n";
        key = "<localleader>jk";
        action = ":MoltenInterrupt<CR>";
        options = {
          silent = true;
          desc = "Interrupt execution";
        };
      }
      {
        mode = "n";
        key = "<localleader>jR";
        action = ":MoltenRestart<CR>";
        options = {
          silent = true;
          desc = "Restart kernel";
        };
      }
      {
        mode = "n";
        key = "<localleader>jI";
        action = ":MoltenInfo<CR>";
        options = {
          silent = true;
          desc = "Show kernel info";
        };
      }
      {
        mode = "n";
        key = "<localleader>jn";
        action = ":MoltenNext<CR>";
        options = {
          silent = true;
          desc = "Go to next cell";
        };
      }
      {
        mode = "n";
        key = "<localleader>jp";
        action = ":MoltenPrev<CR>";
        options = {
          silent = true;
          desc = "Go to previous cell";
        };
      }
    ];

    # Configure Molten options via extraConfigLua instead of globals
    extraConfigLuaPre = ''
      -- Set Molten configuration via vim.g instead of using the globals option
      vim.g.molten_image_provider = "image.nvim"
      vim.g.molten_output_win_max_height = 20
      vim.g.molten_virt_text_output = true
      vim.g.molten_wrap_output = true
      vim.g.molten_virt_lines_off_by_1 = true
      vim.g.molten_auto_open_output = false
      vim.g.molten_copy_output = false
      vim.g.molten_output_crop_border = true
      vim.g.molten_output_win_border = { "", "━", "", "" }

      -- Terminal-specific configuration for Foot and Ghostty
      local foot_socket = os.getenv("FOOT_DIRECT_INPUT_FD")
      local ghostty_sock = os.getenv("GHOSTTY_RESOURCES_DIR")

      -- Add useful status line integration
      vim.api.nvim_create_autocmd("User", {
        pattern = "MoltenInitPost",
        callback = function()
          vim.notify("Molten kernel initialized", vim.log.levels.INFO)
        end
      })
    '';
  };
}
