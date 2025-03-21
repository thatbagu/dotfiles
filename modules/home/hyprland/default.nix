{ inputs, pkgs, lib, config, ... }:
with lib;
let cfg = config.modules.hyprland;
in {
  options.modules.hyprland = { enable = mkEnableOption "hyprland"; };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [ fuzzel wlsunset wl-clipboard ];

    wayland.windowManager.hyprland = {
      enable = true;
      xwayland.enable = true;
      extraConfig = builtins.readFile ./hyprland.conf;
    };
  };
}
