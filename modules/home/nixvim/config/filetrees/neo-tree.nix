{ lib, config, ... }: {
  options = { neo-tree.enable = lib.mkEnableOption "Enable neo-tree module"; };
  config = lib.mkIf config.neo-tree.enable {

    plugins.neo-tree = {
      enable = true;
      settings = {
        enable_diagnostics = true;
        enable_git_status = true;
        enable_modified_markers = true;
        enable_refresh_on_write = true;
        close_if_last_window = true;
        popup_border_style = "rounded";
        buffers = {
          bind_to_cwd = false;
          follow_current_file.enabled = true;
        };
        window = {
          width = 40;
          height = 15;
          auto_expand_width = false;
          mappings."<space>" = "none";
        };
      };
    };

    # keymaps = [
    #   {
    #     mode = "n";
    #     key = "<leader>e";
    #     action = ":Neotree toggle reveal_force_cwd<cr>";
    #     options = {
    #       silent = true;
    #       desc = "Explorer NeoTree (root dir)";
    #     };
    #   }
    #   {
    #     mode = "n";
    #     key = "<leader>E";
    #     action = "<cmd>Neotree toggle<CR>";
    #     options = {
    #       silent = true;
    #       desc = "Explorer NeoTree (cwd)";
    #     };
    #   }
    #   {
    #     mode = "n";
    #     key = "<leader>be";
    #     action = ":Neotree buffers<CR>";
    #     options = {
    #       silent = true;
    #       desc = "Buffer explorer";
    #     };
    #   }
    #   {
    #     mode = "n";
    #     key = "<leader>ge";
    #     action = ":Neotree git_status<CR>";
    #     options = {
    #       silent = true;
    #       desc = "Git explorer";
    #     };
    #   }
    # ];
  };
}
