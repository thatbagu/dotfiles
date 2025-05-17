{ lib, config, ... }:

with lib;
let cfg = config.modules.xdg;

in {
    imports = [
        ./yazi-file-handler.nix
    ];
    
    options.modules.xdg = { enable = mkEnableOption "xdg"; };
    config = mkIf cfg.enable {
        xdg.userDirs = {
            enable = true;
            documents = "$HOME/Documents/";
            download = "$HOME/Downloads/";
            videos = "$HOME/Videos/";
            music = "$HOME/Music/";
            pictures = "$HOME/Pictures";
            extraConfig = {
                XDG_CODE_DIR = "$HOME/Code";  # Example of custom dir
                # Add any other custom directories here
            };
        };
    };
}
