{ pkgs, lib, config, ... }:

with lib;
let cfg = config.modules.swaylock;

in {
  options.modules.swaylock = { enable = mkEnableOption "swaylock"; };
  config = mkIf cfg.enable {
    # Enable swaylock
    programs.swaylock = {
      enable = true;
      package = pkgs.swaylock-effects;
    };

    stylix.targets.swaylock.enable = true;
  };
}
