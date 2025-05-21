{ lib, config, pkgs, ... }: {
  options = {
    image-nvim.enable = lib.mkEnableOption "Enable image.nvim module";
  };
  config = lib.mkIf config.image-nvim.enable {
    plugins.image = {
      enable = true;
      settings = {
        # Detect backend based on OS/terminal
        backend = "auto"; # 'auto' will attempt to detect the best backend
        integrations = { }; # Disable markdown integration, let molten handle it
        max_width =
          100; # Important to prevent terminal crashes with large images
        max_height =
          12; # Important to prevent terminal crashes with large images
        max_height_window_percentage =
          null; # Set to math.huge in Lua, use null in Nix
        max_width_window_percentage =
          null; # Set to math.huge in Lua, use null in Nix
        window_overlap_clear_enabled = true; # Clear images when windows overlap
        window_overlap_clear_ft_ignore = [ "cmp_menu" "cmp_docs" "" ];
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

    extraConfigLua = ''
      -- Configure image.nvim with terminal-specific settings
      local image = require('image')
      local os_name = vim.loop.os_uname().sysname

      -- Convert null to math.huge for window percentage limits
      local image_config = image.config
      if image_config then
        if image_config.max_height_window_percentage == nil then
          image_config.max_height_window_percentage = math.huge
        end
        if image_config.max_width_window_percentage == nil then
          image_config.max_width_window_percentage = math.huge
        end
      end

      -- Try to auto-detect terminal and configure accordingly
      local backend = 'auto'
      local term = os.getenv("TERM")
      local foot_socket = os.getenv("FOOT_DIRECT_INPUT_FD")
      local ghostty_sock = os.getenv("GHOSTTY_RESOURCES_DIR")

      -- For Foot terminal on Linux
      if foot_socket then
        backend = 'sixel'
      end

      -- For Ghostty on macOS
      if ghostty_sock then
        backend = 'kitty'
        -- Ghostty is compatible with Kitty's graphics protocol
      end

      -- Apply the detected backend
      image.setup({
        backend = backend
      })

      -- Add notification for the current backend
      vim.defer_fn(function()
        if image.backend and image.backend._name then
          vim.notify('Image.nvim using ' .. image.backend._name .. ' backend', vim.log.levels.INFO)
        end
      end, 1000)
    '';
  };
}
