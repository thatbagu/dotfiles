{ pkgs, lib, config, ... }:

with lib;
let cfg = config.modules.qbittorrent;

in {
  options.modules.qbittorrent = { enable = mkEnableOption "qbittorrent"; };

  config = mkIf cfg.enable {
    programs.qbittorrent = {
      enable = true;
      theme = {
        name = "catppuccin-mocha";
        source = pkgs.fetchFromGitHub {
          owner = "catppuccin";
          repo = "qbittorrent";
          rev = "a11e25d3f9abf53eafb966e5e1173859eb333875";
          hash = "sha256-vYwUYhBMFUB7xnsQsHBhHxoGwj2dpxJvYY/9Qy0H+Yk=";
        };
      };
    };
  };
}
