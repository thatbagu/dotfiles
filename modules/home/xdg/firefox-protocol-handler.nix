{ lib, config, ... }:

with lib;
let cfg = config.modules.xdg;

in {
  config = mkIf cfg.enable {
    # Create a desktop entry for handling file:// URLs directly
    xdg.desktopEntries.firefox-file-protocol-handler = {
      name = "Firefox File Protocol Handler";
      genericName = "File Protocol Handler";
      comment = "Handle file:// URLs from Firefox";
      exec = "firefox-file-handler %u";
      terminal = false;
      categories = [ "System" "Utility" ];
      mimeType = [ "x-scheme-handler/file" ];
      type = "Application";
      noDisplay = true;
    };

    # Set as the default handler for file:// URLs
    xdg.mimeApps = {
      enable = true;
      defaultApplications = {
        "x-scheme-handler/file" = [ "firefox-file-protocol-handler.desktop" ];
      };
    };
  };
}
