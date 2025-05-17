{ lib, config, pkgs, ... }:

with lib;
let cfg = config.modules.yazi;

in {
  options.modules.yazi = { enable = mkEnableOption "yazi"; };
  config = mkIf cfg.enable {
    programs.yazi = {
      enable = true;
      enableBashIntegration = true;
      enableFishIntegration = true;
      
      # Yazi configuration
      settings = {
        manager = {
          show_hidden = false;
          sort_by = "natural";
          sort_sensitive = false;
          sort_reverse = false;
          sort_dir_first = true;
        };
        
        preview = {
          max_width = 1920;
          max_height = 1080;
          image = {
            enabled = true;
            backend = "kitty";
          };
        };
      };
      
      # Custom keybindings
      keymap = {
        manager.prepend_keymap = [
          # Add a special keybinding for file picker mode
          { on = ["<Enter>"];
            run = ''
              :if [[ -n "$YAZI_FILE_PICKER_OUTPUT" ]]; then
                :shell echo "$PWD/$CURRENT" > "$YAZI_FILE_PICKER_OUTPUT"; quit
              :else
                :open
              :end
            '';
            desc = "Open the selected file or pick it in file picker mode";
          }
        ];
      };
    };
    
    # Create the Yazi config directory
    home.file.".config/yazi/init.lua".text = ''
      -- Yazi initialization script
      
      -- Check if we're in file picker mode
      function is_file_picker_mode()
        return os.getenv("YAZI_FILE_PICKER_OUTPUT") ~= nil
      end
      
      -- Set up file picker mode
      if is_file_picker_mode() then
        -- Show a message that we're in file picker mode
        ya.notify("File picker mode: Press Enter to select a file")
      end
    '';
    
    # Add the file picker script to the path
    home.packages = [
      (pkgs.writeShellScriptBin "yazi-file-picker" (builtins.readFile ../scripts/yazi-file-picker.sh))
    ];
  };
}
