{ inputs, lib, config, pkgs, ... }:
with lib;
let cfg = config.modules.firefox;

in {
  options.modules.firefox = { enable = mkEnableOption "firefox"; };
  config = mkIf cfg.enable {
    programs.firefox = {
      enable = true;
      package = pkgs.firefox.override {
        extraNativeMessagingHosts = [ pkgs.tridactyl-native ];
      };
      profiles.${config.home.username} = {
        isDefault = true;
        extensions = with inputs.firefox-addons.packages."x86_64-linux"; [
          bitwarden
          ublock-origin
          sponsorblock
          darkreader
          tridactyl
          multi-account-containers
          youtube-shorts-block
        ];
        search.engines = {
          "Nix Packages" = {
            urls = [{
              template = "https://search.nixos.org/packages";
              params = [
                {
                  name = "type";
                  value = "packages";
                }
                {
                  name = "channel";
                  value = "unstable";
                }
                {
                  name = "query";
                  value = "{searchTerms}";
                }
              ];
            }];
            icon =
              "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
            definedAliases = [ "@n" ];
          };
        };
        search.force = true;
        settings = {
          "browser.disableResetPrompt" = true;
          "browser.download.panel.shown" = true;
          "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
          "browser.shell.checkDefaultBrowser" = false;
          "browser.shell.defaultBrowserCheckCount" = 1;
          "browser.startup.homepage" = "https://start.duckduckgo.com";
          "browser.uiCustomization.state" = ''
            {"placements":{"widget-overflow-fixed-list":[],"nav-bar":["back-button","forward-button","stop-reload-button","home-button","urlbar-container","downloads-button","library-button","ublock0_raymondhill_net-browser-action","_testpilot-containers-browser-action"],"toolbar-menubar":["menubar-items"],"TabsToolbar":["tabbrowser-tabs","new-tab-button","alltabs-button"],"PersonalToolbar":["import-button","personal-bookmarks"]},"seen":["save-to-pocket-button","developer-button","ublock0_raymondhill_net-browser-action","_testpilot-containers-browser-action"],"dirtyAreaCache":["nav-bar","PersonalToolbar","toolbar-menubar","TabsToolbar","widget-overflow-fixed-list"],"currentVersion":18,"newElementCount":4}'';
          "dom.security.https_only_mode" = true;
          "identity.fxaccounts.enabled" = false;
          "privacy.trackingprotection.enabled" = true;
          "signon.rememberSignons" = false;
          # Use ranger as the default file manager
          "widget.use-xdg-desktop-portal.file-picker" = 1;
          "widget.use-xdg-desktop-portal.mime-handler" = 1;
          "browser.download.dir" = "/home/${config.home.username}/Downloads";
          "browser.download.folderList" = 2;
          "browser.download.useDownloadDir" = true;
          "browser.download.always_ask_before_handling_new_types" = true;
          # Enable Tridactyl on all pages
          "extensions.webextensions.tridactyl.binds.json" = true;
          "extensions.webextensions.tridactyl.enabled" = true;
          "xpinstall.signatures.required" = false;
          # Allow Tridactyl on Mozilla domains
          "extensions.webextensions.restrictedDomains" = "";
        };
      };
    };
  };
}
