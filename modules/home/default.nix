{ inputs, pkgs, config, ... }: {
  home.stateVersion = "24.05";
  imports = [
    # GUI Applications
    ./firefox
    ./foot
    ./dunst
    ./hyprland
    ./papertoy
    ./fuzzel
    ./waybar
    ./rtorrent
    ./gtk
    ./yazi
    ./swaylock

    # Terminal & Shell
    ./nixvim
    ./fish
    ./zellij
    ./k9s

    # Development
    ./git

    # System
    ./xdg
    ./packages
    ./scripts
  ];
}
