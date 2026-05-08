{ pkgs, lib, config, inputs, ... }:

with lib;
let
  cfg = config.modules.ghostty;

  # Determine if we're on macOS
  isDarwin = pkgs.stdenv.isDarwin;

  # Define the configuration content
  ghosttyConfig = ''
    # Ghostty configuration
    font-family = "JetBrainsMono Nerd Font"
    font-size = 12

    # Catppuccin Mocha Theme
    # Base colors
    background = #1e1e2e
    foreground = #cdd6f4

    # Normal colors
    palette = 0=#45475a
    palette = 1=#f38ba8
    palette = 2=#a6e3a1
    palette = 3=#f9e2af
    palette = 4=#89b4fa
    palette = 5=#f5c2e7
    palette = 6=#94e2d5
    palette = 7=#bac2de

    # Bright colors
    palette = 8=#585b70
    palette = 9=#f38ba8
    palette = 10=#a6e3a1
    palette = 11=#f9e2af
    palette = 12=#89b4fa
    palette = 13=#f5c2e7
    palette = 14=#94e2d5
    palette = 15=#a6adc8

    # Special colors
    cursor-color = #f5e0dc
    selection-background = #585b70
    selection-foreground = #cdd6f4

    # Terminal behavior
    shell-integration = enabled
    cursor-style = block
    cursor-blink = false

    # Window settings
    window-padding-x = 10
    window-padding-y = 10

    # Key bindings
    keybind = ctrl+shift+t=new_tab
    keybind = ctrl+shift+w=close_tab
    keybind = ctrl+tab=next_tab
    keybind = ctrl+shift+tab=previous_tab
  '';

in {
  options.modules.ghostty = { enable = mkEnableOption "ghostty"; };

  config = mkIf cfg.enable {
    # Import the ghostty package from the flake input
    home.packages = [ inputs.ghostty.packages.${pkgs.stdenv.hostPlatform.system}.default ];

    # Configure ghostty based on platform
    xdg.configFile =
      mkIf (!isDarwin) { "ghostty/config".text = ghosttyConfig; };

    # On macOS, use the application-specific configuration path
    home.file =
      mkIf isDarwin { ".config/ghostty/config".text = ghosttyConfig; };
  };
}

