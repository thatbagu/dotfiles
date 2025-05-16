{ pkgs, lib, config, ... }:
with lib;
let
  cfg = config.modules.stylix;
  wallpaper = pkgs.copyPathToStore
    ../../../pics/wallpaper.png; # This ensures the image is in the Nix store
in {
  options.modules.stylix = { enable = mkEnableOption "stylix"; };
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
          applications = 12;
          desktop = 12;
          terminal = 12;
        };
      };
      # Add Bibata cursor
      cursor = {
        package = pkgs.bibata-cursors;
        name = "Bibata-Modern-Classic";
        size = 24;
      };
      polarity = "dark"; # Explicitly set dark mode
    };
  };
}
