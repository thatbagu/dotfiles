{ lib, config, ... }: {
  options = { harpoon.enable = lib.mkEnableOption "Enable harpoon module"; };
  config = lib.mkIf config.harpoon.enable {
    plugins.harpoon = {
      enable = true;
      enableTelescope = true;
    };

    keymaps = [
      {
        mode = "n";
        key = "<leader>ha";
        action.__raw = "function() require('harpoon'):list():add() end";
        options = { desc = "Add file to harpoon"; };
      }
      {
        mode = "n";
        key = "<C-e>";
        action.__raw =
          "function() require('harpoon').ui:toggle_quick_menu(require('harpoon'):list()) end";
        options = { desc = "Toggle harpoon quick menu"; };
      }
      {
        mode = "n";
        key = "<leader>hj";
        action.__raw = "function() require('harpoon'):list():select(1) end";
        options = { desc = "Navigate to harpoon file 1"; };
      }
      {
        mode = "n";
        key = "<leader>hk";
        action.__raw = "function() require('harpoon'):list():select(2) end";
        options = { desc = "Navigate to harpoon file 2"; };
      }
      {
        mode = "n";
        key = "<leader>hl";
        action.__raw = "function() require('harpoon'):list():select(3) end";
        options = { desc = "Navigate to harpoon file 3"; };
      }
      {
        mode = "n";
        key = "<leader>hm";
        action.__raw = "function() require('harpoon'):list():select(4) end";
        options = { desc = "Navigate to harpoon file 4"; };
      }
    ];
  };
}
