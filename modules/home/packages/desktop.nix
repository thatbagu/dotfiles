{ pkgs, lib, config, ... }:
with lib;
let cfg = config.modules.packages.desktop;
in {
  options.modules.packages.desktop = {
    enable = mkEnableOption "desktop packages";
  };
  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      # Sound
      pamixer
      psmisc
      alsa-utils

      # Media
      ffmpeg
      imagemagick
      mpv
      pqiv
      anki-bin

      # Wayland Tools
      grim
      slurp
      slop
      waybar
      fuzzel
      hyprpaper

      # Browsers
      browsh

      # System Notifications
      libnotify

      # Graphics
      gimp

      # System Utils
      brightnessctl
      antimicrox
    ];
  };
}

