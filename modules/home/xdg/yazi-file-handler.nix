{ lib, config, ... }:

with lib;
let cfg = config.modules.xdg;

in {
  config = mkIf cfg.enable {
    # Create a desktop entry for Yazi to handle file:// URLs
    xdg.desktopEntries.yazi-file-handler = {
      name = "Yazi File Manager";
      genericName = "File Manager";
      comment = "Open directories in Yazi";
      exec = "firefox-file-handler %u";
      terminal = false;
      categories = [ "System" "FileManager" "Utility" ];
      mimeType = [ 
        "inode/directory" 
        "x-scheme-handler/file" 
        "application/x-gnome-saved-search"
      ];
      type = "Application";
    };

    # Set Yazi as the default file manager
    xdg.mimeApps = {
      enable = true;
      defaultApplications = {
        "inode/directory" = [ "yazi-file-handler.desktop" ];
        "x-scheme-handler/file" = [ "yazi-file-handler.desktop" ];
        "application/x-gnome-saved-search" = [ "yazi-file-handler.desktop" ];
      };
    };
  };
}
