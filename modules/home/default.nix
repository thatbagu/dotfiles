{ inputs, pkgs, config, ... }: {
  home.stateVersion = "24.05";
  imports = [
    # GUI Applications
    ./firefox
    ./foot
    ./dunst
    ./hyprland
    ./fuzzel
    ./waybar
    ./rtorrent

    # Terminal & Shell
    ./nixvim
    ./nushell
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
