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

in {
    options.modules.scripts = { enable = mkEnableOption "scripts"; };
    config = mkIf cfg.enable {
        home.packages = [
            screen bandw maintenance firefox-file-handler
        ];
    };
}
