{ pkgs, lib, config, ... }:

with lib;
let cfg = config.modules.swaylock;

in {
  options.modules.swaylock = { enable = mkEnableOption "swaylock"; };
  config = mkIf cfg.enable {
    # Enable swaylock
    programs.swaylock = {
      enable = true;
      package = pkgs.swaylock-effects; # Use swaylock-effects for more features
    };

    # Additional swaylock configuration
    home.file.".config/swaylock/config".text = ''
      # Additional manual configurations can go here if needed
      # These will be merged with stylix-generated settings

      # Security settings
      ignore-empty-password
      show-failed-attempts

      # Appearance settings (these may be overridden by stylix)
      indicator-caps-lock
      indicator-radius=100
      indicator-thickness=10
    '';
  };
}

