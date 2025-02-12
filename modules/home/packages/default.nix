{ pkgs, lib, config, ... }:
with lib;
let cfg = config.modules.packages;
in {
  options.modules.packages = { enable = mkEnableOption "packages"; };
  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      # Development
      git
      gh
      lua
      terraform
      terragrunt
      opentofu

      # Python
      python3
      ruff
      python311Packages.flake8

      # Go
      go
      golangci-lint
      gopls
      go-tools

      # Nix
      statix
      nil
      nixfmt

      # Rust
      rustc
      cargo
      rustfmt
      rust-analyzer
      clippy
      gcc

      # Cloud & Container Tools
      google-cloud-sdk
      awscli
      kubectl
      k9s

      # System Utils
      htop
      ranger
      fzf
      ripgrep
      bat
      eza
      unzip
      tealdeer
      age
      brightnessctl
      tree
      antimicrox

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
    ];
  };
}
