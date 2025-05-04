{ pkgs, lib, config, ... }:

with lib;
let cfg = config.modules.desktop;
in {
  options.modules.desktop = { enable = mkEnableOption "desktop"; };

  config = mkIf cfg.enable {
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

    # Wayland stuff: enable XDG integration, allow sway to use brillo
    xdg = {
      portal = {
        enable = true;
        extraPortals = with pkgs; [
          xdg-desktop-portal-wlr
          xdg-desktop-portal-gtk
        ];
        # Add this new configuration for XDG portal
        config = { common.default = "*"; };
      };
    };

    # Remove unnecessary preinstalled packages
    services.xserver.desktopManager.xterm.enable = false;

    # For backlight control
    programs.light.enable = true;

    # Enable dconf
    programs.dconf.enable = true;

    # Audio setup
    security.rtkit.enable = true;

    # Add this to your configuration.nix file
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
      ANKI_WAYLAND = "1";
      DISABLE_QT5_COMPAT = "0";
    }];
  };
}

