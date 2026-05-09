{ pkgs, lib, config, ... }:
with lib;
let
  cfg = config.modules.stylix;
  wallpaper = pkgs.copyPathToStore
    ../../../pics/wallpaper.png; # This ensures the image is in the Nix store
in {
  options.modules.stylix = {
    enable = mkEnableOption "stylix";
    scale = mkOption {
      type = types.float;
      default = 1.0;
      description = "Overall UI scale factor";
    };
  };
  config = mkIf cfg.enable {
    stylix = {
      enable = true;
      image = wallpaper;
      # Force dark mode
      base16Scheme =
        "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";
      opacity = {
        terminal = 0.9;
        applications = 0.9;
        desktop = 0.9;
      };
      fonts = {
        monospace = {
          name = "JetBrainsMono Nerd Font";
          package = pkgs.nerd-fonts.jetbrains-mono;
        };
        sizes = {
          # Scale font sizes based on scale factor
          applications = builtins.floor (12 * cfg.scale);
          desktop = builtins.floor (12 * cfg.scale);
          terminal = builtins.floor (12 * cfg.scale);
        };
      };
      # Add Bibata cursor with scaled size
      cursor = {
        package = pkgs.bibata-cursors;
        name = "Bibata-Modern-Classic";
        size = builtins.floor (20 * cfg.scale);
      };
      polarity = "dark"; # Explicitly set dark mode
      targets.qt.enable = false;
    };

    # For GTK3 applications (integer scaling only)
    environment.sessionVariables = {
      # GTK3 only supports integer scaling
      GDK_SCALE = toString (builtins.ceil cfg.scale);
      # Compensate for integer scaling with DPI scaling for text
      GDK_DPI_SCALE = toString (cfg.scale / (builtins.ceil cfg.scale));
    };
  };
}
