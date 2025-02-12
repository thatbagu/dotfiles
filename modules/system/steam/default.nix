{ pkgs, lib, config, ... }:

with lib;
let cfg = config.modules.steam;

in {
    options.modules.steam = {
        enable = mkEnableOption "steam";
    };
    
    config = mkIf cfg.enable {
        # Move all these settings to the root config level, not under modules.steam
        programs.gamemode.enable = true;
        
        hardware = {
            bluetooth.enable = true;
            graphics = {
                enable = true;
                enable32Bit = true;
            };
        };
        
        programs.steam = {
            enable = true;
            gamescopeSession.enable = true;
            package = pkgs.steam.override {
                extraPkgs = pkgs: with pkgs; [
                    xorg.libXcursor
                    xorg.libXi
                    xorg.libXinerama
                    xorg.libXScrnSaver
                    libpng
                    libpulseaudio
                    libvorbis
                    source-sans
                    source-serif
                    source-han-sans
                    source-han-serif
                    pipewire
                    udev
                    alsa-lib
                    vulkan-loader
                    xorg.libX11
                    xorg.libXcursor
                    xorg.libXi
                    xorg.libXrandr
                    libxkbcommon
                    wayland
                    mesa
                    libglvnd
                ];
            };
        };
    };
}
