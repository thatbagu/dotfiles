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
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
      wireplumber.enable = true;
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

