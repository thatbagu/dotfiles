{ pkgs, lib, config, ... }:

with lib;
let 
    cfg = config.modules.scripts;
    screen = pkgs.writeShellScriptBin "screen" ''${builtins.readFile ./screen}'';
    bandw = pkgs.writeShellScriptBin "bandw" ''${builtins.readFile ./bandw}'';
    maintenance = pkgs.writeShellScriptBin "maintenance" ''${builtins.readFile ./maintenance}'';
    firefox-file-handler = pkgs.writeShellScriptBin "firefox-file-handler" ''
        ${builtins.readFile ./firefox-file-handler.sh}
    '';
    firefox-custom-file-picker = pkgs.writeShellScriptBin "firefox-custom-file-picker" ''
        ${builtins.readFile ./firefox-custom-file-picker.sh}
    '';

in {
    options.modules.scripts = { enable = mkEnableOption "scripts"; };
    config = mkIf cfg.enable {
        home.packages = [
            screen bandw maintenance firefox-file-handler firefox-custom-file-picker
            # Add wl-clipboard for copying file paths
            pkgs.wl-clipboard
            # Add libnotify for notifications
            pkgs.libnotify
        ];
    };
}
