{ lib, config, pkgs, ... }: {
  options = {
    image-nvim.enable = lib.mkEnableOption "Enable image.nvim module";
  };
  config = lib.mkIf config.image-nvim.enable {
    plugins.image = {
      enable = true;
      settings = {
        # Use "kitty" as the default backend as it's more widely compatible
        backend = "kitty"; # Valid values are "kitty" or "ueberzug"
        integrations = { }; # Disable markdown integration, let molten handle it
        max_width =
          100; # Important to prevent terminal crashes with large images
        max_height =
          12; # Important to prevent terminal crashes with large images
      };
    };

    # Add dependencies for image.nvim
    extraPackages = with pkgs; [
      # ImageMagick is needed by all backends for image processing
      imagemagick

      # For Ueberzug (fallback on Linux)
      ueberzug

      # Other useful packages for image manipulation
      libsixel # For terminals that support sixel protocol
    ];

    extraConfigLuaPre = ''
      -- Configure image.nvim with terminal-specific settings
      -- This will run after the plugin is loaded
      vim.api.nvim_create_autocmd("User", {
        pattern = "ImageLoaded",
        callback = function()
          local foot_socket = os.getenv("FOOT_DIRECT_INPUT_FD")
          local ghostty_sock = os.getenv("GHOSTTY_RESOURCES_DIR")
          
          -- Apply config after image.nvim is fully loaded
          vim.defer_fn(function()
            local image = require('image')
            if not image or not image.setup then return end
            
            -- Set window percentage limits to math.huge
            if image.config then
              image.config.max_height_window_percentage = math.huge
              image.config.max_width_window_percentage = math.huge
            end
            
            -- For Foot terminal on Linux
            if foot_socket then
              image.setup({ backend = "ueberzug" })
              vim.notify("Foot terminal detected, configured image.nvim to use ueberzug backend", vim.log.levels.INFO)
            end
            
            -- For Ghostty on macOS
            if ghostty_sock then
              image.setup({ backend = "kitty" })
              vim.notify("Ghostty terminal detected, configured image.nvim to use kitty backend", vim.log.levels.INFO)
            end
            
            -- Show current backend
            if image.backend and image.backend._name then
              vim.notify('Image.nvim using ' .. image.backend._name .. ' backend', vim.log.levels.INFO)
            end
          end, 1000)
        end
      })

      -- Create event if it doesn't exist
      vim.defer_fn(function()
        vim.api.nvim_exec_autocmds("User", {pattern = "ImageLoaded"})
      end, 1500)
    '';
  };
}
