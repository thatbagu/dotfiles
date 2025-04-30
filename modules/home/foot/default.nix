{ pkgs, lib, config, ... }:

with lib;
let cfg = config.modules.foot;

in {
  options.modules.foot = { enable = mkEnableOption "foot"; };
  config = mkIf cfg.enable {
    programs.foot = {
      enable = true;
      server.enable = false;
      settings = {
        main = {
          pad = "12x12";
          term = "xterm-256color";
        };
        tweak = { sixel = true; };
      };
    };
  };
}
