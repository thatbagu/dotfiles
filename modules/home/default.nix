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

    # Terminal & Shell
    ./nixvim
    ./nushell
    ./zellij

    # Development
    ./git

    # System
    ./xdg
    ./packages
    ./scripts
  ];
}
