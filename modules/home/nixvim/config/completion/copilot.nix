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
        claude = {
          endpoint = "https://api.anthropic.com";
          model = "claude-3-5-sonnet-20241022";
          temperature = 0;
          max_tokens = 4096;
        };
        behaviour = {
          auto_suggestions = false;
          auto_set_highlight_group = true;
          auto_set_keymaps = true;
          minimize_diff = true;
        };
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
          };
        };
      };
    };
    options.laststatus = 3;
  };
}
