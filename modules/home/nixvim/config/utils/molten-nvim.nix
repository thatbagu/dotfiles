{ lib, config, pkgs, ... }: {
  options = {
    molten-nvim.enable = lib.mkEnableOption "Enable molten-nvim module";
  };
  config = lib.mkIf config.molten-nvim.enable {
    plugins.molten = {
      enable = true;
      settings = { };
    };

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

    # Global configuration for molten
    globals = {
      molten_image_provider =
        "image.nvim"; # Will use image.nvim with the proper backend
      molten_output_win_max_height = 20;
      molten_virt_text_output = true;
      molten_wrap_output = true;
      molten_virt_lines_off_by_1 = true; # Better for markdown
      molten_auto_open_output = false; # Don't auto-open output window
      molten_copy_output = false;
      molten_output_crop_border = true;
      molten_output_win_border = [ "" "━" "" "" ];
    };

    # Add recommended keymaps for molten
    keymaps = [
      {
        mode = "n";
        key = "<localleader>mi";
        action = ":MoltenInit<CR>";
        options = {
          silent = true;
          desc = "Initialize Molten";
        };
      }
      {
        mode = "n";
        key = "<localleader>me";
        action = ":MoltenEvaluateOperator<CR>";
        options = {
          silent = true;
          desc = "Run operator selection";
        };
      }
      {
        mode = "n";
        key = "<localleader>ml";
        action = ":MoltenEvaluateLine<CR>";
        options = {
          silent = true;
          desc = "Evaluate line";
        };
      }
      {
        mode = "n";
        key = "<localleader>mr";
        action = ":MoltenReevaluateCell<CR>";
        options = {
          silent = true;
          desc = "Re-evaluate cell";
        };
      }
      {
        mode = "v";
        key = "<localleader>m";
        action = ":<C-u>MoltenEvaluateVisual<CR>gv";
        options = {
          silent = true;
          desc = "Evaluate visual selection";
        };
      }
      {
        mode = "n";
        key = "<localleader>md";
        action = ":MoltenDelete<CR>";
        options = {
          silent = true;
          desc = "Delete cell";
        };
      }
      {
        mode = "n";
        key = "<localleader>mh";
        action = ":MoltenHideOutput<CR>";
        options = {
          silent = true;
          desc = "Hide output";
        };
      }
      {
        mode = "n";
        key = "<localleader>ms";
        action = ":noautocmd MoltenEnterOutput<CR>";
        options = {
          silent = true;
          desc = "Show/enter output";
        };
      }
    ];

    # Add autocommands for better integration with your workflow
    extraConfigLua = ''
      -- Add useful status line integration
      vim.api.nvim_create_autocmd("User", {
        pattern = "MoltenInitPost",
        callback = function()
          vim.notify("Molten kernel initialized", vim.log.levels.INFO)
        end
      })

      -- Add molten status to your statusline (useful with lualine)
      -- If you have lualine, you can add this to a section:
      -- vim.api.nvim_create_autocmd("User", {
      --   pattern = {"MoltenInitPost", "MoltenKernelReady"},
      --   callback = function()
      --     -- If lualine is available, refresh it
      --     pcall(function() require("lualine").refresh() end)
      --   end
      -- })

      -- Terminal-specific configuration for Foot and Ghostty
      local foot_socket = os.getenv("FOOT_DIRECT_INPUT_FD")
      local ghostty_sock = os.getenv("GHOSTTY_RESOURCES_DIR")

      -- Foot terminal might need some tweaking for virtual text
      if foot_socket then
        -- Foot may work better with non-virtual text in some cases
        -- Uncomment the next line if you experience issues with virtual text
        -- vim.g.molten_virt_text_output = false
      end

      -- Ghostty specific settings (if needed)
      if ghostty_sock then
        -- Ghostty should work well with the defaults
        -- You can add specific settings here if needed
      end

      -- Auto-initialize the kernel when opening supported filetypes (optional)
      -- vim.api.nvim_create_autocmd("FileType", {
      --   pattern = {"python", "r", "julia"},
      --   callback = function()
      --     vim.cmd("MoltenInit")
      --   end
      -- })
    '';
  };
}
