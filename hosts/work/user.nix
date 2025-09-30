{ config, lib, inputs, ... }: {
  imports = [ ../../modules/home/default.nix ];
  config.modules = {
    # GUI Applications
    firefox.enable = true;
    # foot.enable = true;
    # dunst.enable = true;
    # hyprland.enable = true;
    # fuzzel.enable = true;
    # waybar.enable = true;
    # obsidian.enable = true;
    # swaylock.enable = true;
    ghostty.enable = true;

    # Terminal & Shell
    nixvim.enable = true;
    fish.enable = true;
    zellij.enable = true;

    # Development
    git.enable = true;

    # System
    xdg.enable = true;
    packages.enable = true;
    scripts.enable = true;
  };
}
