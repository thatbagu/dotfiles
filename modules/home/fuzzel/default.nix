{ pkgs, lib, config, ... }:
with lib;
let cfg = config.modules.fuzzel;
in {
  options.modules.fuzzel = { enable = mkEnableOption "fuzzel"; };
  config = mkIf cfg.enable {
    programs.fuzzel.enable = true;
    programs.fuzzel.settings = {
      main = {
        terminal = "${pkgs.foot}/bin/foot";
        layer = "overlay";
        width = 50; # Width in characters
        lines = 15; # Number of lines to display
        icons-enabled = false; # Explicitly disable icons
        font = lib.mkForce "monospace:size=14";
      };
    };
  };
}
