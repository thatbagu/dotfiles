{ pkgs, lib, config, ... }:

with lib;
let cfg = config.modules.dunst;

in {
  options.modules.dunst = { enable = mkEnableOption "dunst"; };
  config = mkIf cfg.enable {
    home.packages = with pkgs; [ dunst ];

    services.dunst = {
      enable = true;
      settings = {
        global = {
          origin = "top-left";
          offset = "60x12";
          separator_height = 2;
          padding = 12;
          horizontal_padding = 12;
          text_icon_padding = 12;
          frame_width = 4;
          idle_threshold = 120;
          line_height = 0;
          format = ''
            <b>%s</b>
            %b'';
          alignment = "center";
          icon_position = "off";
          startup_notification = "false";
          corner_radius = 12;

          timeout = 2;
        };
      };
    };
  };
}
