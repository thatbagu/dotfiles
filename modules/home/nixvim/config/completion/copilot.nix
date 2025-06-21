{ lib, config, ... }: {
  options = {
    avante = {
      enable = lib.mkEnableOption "Enable avante module";
      position = lib.mkOption {
        type = lib.types.enum [ "left" "right" "top" "bottom" ];
        default = "right";
        description = "Position of the avante sidebar";
      };
      width = lib.mkOption {
        type = lib.types.int;
        default = 30;
        description = "Width of the sidebar";
      };
    };
  };
  config = lib.mkIf config.avante.enable {
    # Enable required dependencies using your existing modules
    plenary.enable = true;
    dressing-nvim.enable = true;
    nui.enable = true;
    cmp.enable = true;
    web-devicons.enable = true;
    plugins.avante = {
      enable = true;
      settings = {
        provider = "claude";
        # Enable cursor planning mode to reduce token usage with complex requests
        behaviour = {
          auto_suggestions = false;
          auto_set_highlight_group = true;
          auto_set_keymaps = true;
          minimize_diff = true;
          enable_token_counting = true;
          # Enable cursor planning mode for more efficient token usage with larger codebases
          enable_cursor_planning_mode = true;
        };
        # Claude configuration with optimized settings - FIXED: using providers.claude
        providers = {
          claude = {
            endpoint = "https://api.anthropic.com";
            model = "claude-3-7-sonnet-20250219";
            timeout = 60000; # Increase timeout to 60 seconds
            extra_request_body = {
              temperature = 0;
              max_tokens = 4096;
            };
          };
        };
        # Optional: Configure a more token-efficient model for applying changes
        cursor_applying_provider =
          "claude"; # Use the same provider but could be set to another
        # Disable unnecessary tools to reduce token usage
        disabled_tools =
          [ "python" ]; # Disable python tool which often uses more tokens
        windows = {
          position = config.avante.position;
          width = config.avante.width;
          sidebar_header = {
            enabled = true;
            align = "center";
            rounded = true;
          };
        };
        mappings = {
          submit = {
            normal = "<CR>";
            insert = "<C-s>";
          };
          sidebar = {
            apply_all = "A";
            apply_cursor = "a";
            switch_windows = "<Tab>";
            retry_user_request = "r";
            edit_user_request = "e";
          };
        };
        # Optional: Configure dual_boost for complex tasks
        dual_boost = {
          enabled = false; # Only enable when needed for complex tasks
          first_provider = "claude";
          second_provider = "claude";
          timeout = 60000;
        };
      };
    };
    keymaps = [{
      mode = "n";
      key = "<leader>at";
      action =
        "function() vim.api.nvim_exec_autocmds('User', { pattern = 'AvanteDisplayTokens' }) end";
      options = {
        silent = true;
        desc = "Display Avante token usage";
      };
    }];
  };
}
