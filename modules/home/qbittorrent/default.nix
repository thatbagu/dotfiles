{ pkgs, lib, config, ... }:
with lib;
let
  cfg = config.modules.qbittorrent;

  # Fetch the theme file directly from the GitHub release
  themeFile = pkgs.fetchurl {
    url =
      "https://github.com/catppuccin/qbittorrent/releases/download/v2.0.1/catppuccin-mocha.qbtheme";
    hash = "sha256-9t31ntiB6kpCPo1Ipz9vUHxZSlYPOYCXiR/LcLyCVeE=";
  };

in {
  options.modules.qbittorrent = { enable = mkEnableOption "qbittorrent"; };

  config = mkIf cfg.enable {
    # Install qBittorrent
    home.packages = [ pkgs.qbittorrent ];

    # Deploy the theme file to the correct location
    xdg.configFile."qBittorrent/themes/catppuccin-mocha.qbtheme".source =
      themeFile;

    # Pre-configure qBittorrent to use the theme
    xdg.configFile."qBittorrent/qBittorrent.conf".text = ''
      [Preferences]
      General\UseCustomUITheme=true
      General\CustomUIThemePath=${config.home.homeDirectory}/.config/qBittorrent/themes/catppuccin-mocha.qbtheme
    '';
  };
}
