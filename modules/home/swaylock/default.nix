{ pkgs, lib, config, ... }:

with lib;
let cfg = config.modules.swaylock;

in {
  options.modules.swaylock = { enable = mkEnableOption "swaylock"; };
  config = mkIf cfg.enable {
    programs.swaylock = {
      enable = true;
      package = pkgs.swaylock-effects;
    };
  };
}
