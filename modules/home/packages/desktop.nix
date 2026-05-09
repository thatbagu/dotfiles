{
  pkgs,
  lib,
  config,
  ...
}:
with lib;
let
  cfg = config.modules.packages.desktop;
in
{
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
      vlc
      obs-studio
      pqiv
      playerctl
      spotify-player

      # Learning & Productivity
      anki

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
      blender
      godot
      inochi-creator
      inochi-session

      # Minecraft
      prismlauncher

      # Emulators
      dolphin-emu

      # System Utils
      brightnessctl
      antimicrox
    ];
  };
}
