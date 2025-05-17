{ ... }: {
  imports = [ ../../modules/home/default.nix ];
  config.modules = {
    # GUI Applications
    firefox.enable = true;
    foot.enable = true;
    dunst.enable = true;
    hyprland.enable = true;
    fuzzel.enable = true;
    waybar.enable = true;
    gtk.enable = true;
    yazi.enable = true;

    # Terminal & Shell
    nixvim.enable = true;
    fish.enable = true;
    zellij.enable = true;

    # Development
    git.enable = true;

    # System
    xdg.enable = true;
    packages.enable = true;
    packages.desktop.enable = true;
    scripts.enable = true;
  };
}
