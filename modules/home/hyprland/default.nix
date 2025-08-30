{ inputs, pkgs, lib, config, ... }:
with lib;
let cfg = config.modules.hyprland;
in {
  options.modules.hyprland = {
    enable = mkEnableOption "hyprland";
    animations = mkOption {
      type = types.bool;
      default = true;
      description = "Enable animations in Hyprland";
    };
    disableBuiltinKeyboard = mkOption {
      type = types.bool;
      default = false;
      description = "Disable the built-in laptop keyboard";
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [ fuzzel wlsunset wl-clipboard ];

    wayland.windowManager.hyprland = {
      enable = true;
      xwayland.enable = true;
      extraConfig = let
              baseConfig = builtins.readFile ./hyprland.conf;
      
              # Configuration for animations
              animationsConfig = if cfg.animations then ''
                # Enable animations
                animations {
                  enabled = true
                }
              '' else ''
                # Disable animations
                animations {
                  enabled = false
                }
              '';
      
              # Configuration to disable the built-in keyboard
              keyboardConfig = if cfg.disableBuiltinKeyboard then ''
                # Disable built-in laptop keyboard
                device {
                  name = at-translated-set-2-keyboard
                  enabled = false
                }
              '' else
                "";
            in baseConfig + "\n" + animationsConfig + "\n" + keyboardConfig;
    };
  };
}
