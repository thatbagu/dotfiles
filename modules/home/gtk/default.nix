{ lib, config, pkgs, ... }:

with lib;
let cfg = config.modules.gtk;

in {
  options.modules.gtk = { enable = mkEnableOption "gtk"; };
  config = mkIf cfg.enable {
    # Configure GTK
    gtk = {
      enable = true;
      
      # GTK3 settings
      gtk3 = {
        extraConfig = {
          gtk-application-prefer-dark-theme = true;
          gtk-button-images = true;
          gtk-menu-images = true;
          gtk-enable-event-sounds = false;
          gtk-enable-input-feedback-sounds = false;
          gtk-xft-antialias = 1;
          gtk-xft-hinting = 1;
          gtk-xft-hintstyle = "hintslight";
          gtk-xft-rgba = "rgb";
        };
      };
      
      # GTK4 settings
      gtk4 = {
        extraConfig = {
          gtk-application-prefer-dark-theme = true;
          gtk-enable-animations = true;
          gtk-xft-antialias = 1;
          gtk-xft-hinting = 1;
          gtk-xft-hintstyle = "hintslight";
          gtk-xft-rgba = "rgb";
        };
      };
    };
    
    # Configure GTK file chooser settings
    dconf.settings = {
      "org/gtk/settings/file-chooser" = {
        sort-directories-first = true;
        show-hidden = false;
        sort-order = "ascending";
        sort-column = "name";
        window-position = "(0, 0)";
        window-size = "(1000, 700)";
        location-mode = "path-bar";
        show-size-column = true;
        show-type-column = true;
      };
    };
    
    # Install GTK themes and related packages
    home.packages = with pkgs; [
      gnome.adwaita-icon-theme
      hicolor-icon-theme
      xdg-desktop-portal-gtk
      xdg-utils
    ];
  };
}
