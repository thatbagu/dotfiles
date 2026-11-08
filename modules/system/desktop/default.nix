{ pkgs, lib, config, ... }:

with lib;
let cfg = config.modules.desktop;
in {
  options.modules.desktop = { enable = mkEnableOption "desktop"; };

  config = mkIf cfg.enable {
    programs.hyprland = {
      enable = true;
      withUWSM = true;
    };

    # Install fonts
    fonts = {
      packages = with pkgs; [
        roboto
        openmoji-color
        nerd-fonts.jetbrains-mono
        noto-fonts-cjk-sans
      ];
      fontconfig = {
        enable = true;
        hinting.autohint = true;
        antialias = true;
        hinting.enable = true;
        defaultFonts = {
          emoji = [ "OpenMoji Color" ];
          monospace = [ "DejaVu Sans Mono" "Liberation Mono" ];
          sansSerif = [ "DejaVu Sans" "Liberation Sans" ];
          serif = [ "DejaVu Serif" "Liberation Serif" ];
        };
      };
    };

    # Input method: fcitx5 owns the whole layout roster (us / ru phonetic / Japanese).
    # Ctrl+Space cycles through them; Mozc gives romaji -> kana -> kanji suggestions.
    i18n.inputMethod = {
      enable = true;
      type = "fcitx5";
      fcitx5 = {
        waylandFrontend = true;
        addons = with pkgs; [ fcitx5-mozc fcitx5-gtk ];
        settings = {
          inputMethod = {
            GroupOrder."0" = "Default";
            "Groups/0" = {
              Name = "Default";
              "Default Layout" = "us";
              DefaultIM = "keyboard-us";
            };
            "Groups/0/Items/0".Name = "keyboard-us";
            "Groups/0/Items/1".Name = "keyboard-ru-phonetic";
            "Groups/0/Items/2".Name = "mozc";
          };
          globalOptions = {
            # Drop the default "toggle first/current IM" trigger so Ctrl+Space just cycles
            "Hotkey/TriggerKeys" = { };
            "Hotkey/EnumerateForwardKeys"."0" = "Control+space";
            "Hotkey/EnumerateBackwardKeys"."0" = "Control+Shift+space";
            Hotkey.EnumerateSkipFirst = "False";
            # No popup near the cursor on switch; waybar shows the current layout
            Behavior = {
              ShowInputMethodInformation = "False";
              ShowInputMethodInformationWhenFocusIn = "False";
            };
          };
        };
      };
    };

    # Wayland stuff: enable XDG integration
    xdg = {
      portal = {
        enable = true;
        # Ensure xdg-desktop-portal is included
        xdgOpenUsePortal = true;
        extraPortals = with pkgs; [
          # Make sure we have all the necessary portals
          xdg-desktop-portal
          xdg-desktop-portal-wlr
          xdg-desktop-portal-gtk
          xdg-desktop-portal-hyprland
        ];
        # Configure XDG portal
        config = {
          common = { default = [ "gtk" "hyprland" ]; };
          hyprland = {
            default = [ "hyprland" "gtk" ];
            "org.freedesktop.impl.portal.FileChooser" = "gtk";
            "org.freedesktop.impl.portal.AppChooser" = "gtk";
            "org.freedesktop.impl.portal.Settings" = "gtk";
          };
        };
        wlr = {
          enable = true;
          settings = {
            screencast = {
              output_name = "eDP-1";
              max_fps = 30;
              chooser_type = "simple";
              chooser_cmd = "${pkgs.slurp}/bin/slurp -f %o -or";
            };
          };
        };
      };
      # Make sure mime types are properly registered
      mime.enable = true;
      # Enable XDG autostart
      autostart.enable = true;
    };

    # Enable D-Bus for proper portal communication
    services.dbus = {
      enable = true;
      packages = with pkgs; [ dconf ];
    };

    # Remove unnecessary preinstalled packages
    services.xserver.desktopManager.xterm.enable = false;

    # Enable dconf
    programs.dconf.enable = true;

    # Audio setup
    security.rtkit.enable = true;

    # Bluetooth audio configuration using Wireplumber instead of media-session
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
      wireplumber.enable = true;
    };

    # Ensure Bluetooth audio services are enabled
    services.blueman.enable = true;

    # Configure wireplumber for better Bluetooth audio handling
    environment.etc = {
      # Main Bluetooth configuration for Wireplumber
      "wireplumber/bluetooth.lua.d/51-bluez-config.lua".text = ''
        bluez_monitor.properties = {
          ["bluez5.enable-sbc-xq"] = true,
          ["bluez5.enable-msbc"] = true,
          ["bluez5.enable-hw-volume"] = true,
          ["bluez5.a2dp.use-aac"] = true,
          ["bluez5.headset-roles"] = "[ hsp_hs hsp_ag hfp_hf hfp_ag ]"
        }
      '';

      # Auto-connect and profile switching configuration
      "wireplumber/main.lua.d/51-auto-connect.lua".text = ''
        table.insert(alsa_monitor.rules, {
          matches = {
            {
              -- Match all Bluetooth sinks
              ["node.name"] = "~bluez_output.*",
            },
          },
          apply_properties = {
            ["node.nick"] = "Bluetooth",
            ["priority.driver"] = 100,
            ["priority.session"] = 100,
            ["node.pause-on-idle"] = false,
          },
        })

        table.insert(bluez_monitor.rules, {
          matches = {
            {
              -- Match all Bluetooth devices
              ["device.name"] = "~bluez_card.*",
            },
          },
          apply_properties = {
            ["bluez5.reconnect-profiles"] = "[ a2dp_sink hsp_ag hfp_ag ]",
            ["bluez5.auto-connect"] = "[ a2dp_sink ]",
            ["bluez5.profile"] = "a2dp_sink",
          },
        })
      '';
    };
    # For battery support
    services.upower.enable = true;

    # Graphics
    hardware.graphics = {
      enable = true;
      enable32Bit = true;
    };

    # Desktop-specific environment variables
    environment.sessionVariables = lib.mkMerge [{
      GTK_RC_FILES = "$HOME/.local/share/gtk-1.0/gtkrc";
      GTK2_RC_FILES = "$HOME/.local/share/gtk-2.0/gtkrc";
      MOZ_ENABLE_WAYLAND = "1";
      MOZ_DBUS_REMOTE = "1";
      MOZ_USE_XINPUT2 = "1";
      ANKI_WAYLAND = "1";
      DISABLE_QT5_COMPAT = "0";
      # Force Firefox to use the portal
      GTK_USE_PORTAL = "1";
    }];
  };
}

