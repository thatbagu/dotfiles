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
    qbittorrent.enable = true;

    # Terminal & Shell
    nixvim.enable = true;
    nushell.enable = true;
    zellij.enable = true;
    k9s.enable = true;

    # Development
    git.enable = true;

    # System
    xdg.enable = true;
    packages.enable = true;
    packages.desktop.enable = true;
    scripts.enable = true;
  };
}
