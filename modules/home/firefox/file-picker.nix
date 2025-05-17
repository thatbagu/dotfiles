{ lib, config, pkgs, ... }:

with lib;
let cfg = config.modules.firefox;

in {
  config = mkIf cfg.enable {
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

    # Install xdg-desktop-portal-gtk for file picker
    home.packages = with pkgs; [
      xdg-desktop-portal-gtk
      xdg-utils
    ];
  };
}
