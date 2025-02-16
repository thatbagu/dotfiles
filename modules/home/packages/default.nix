{ pkgs, lib, config, ... }:
with lib;
let cfg = config.modules.packages;
in {
  imports = [ ./core.nix ./desktop.nix ];

  options.modules.packages = { enable = mkEnableOption "packages"; };

  config = mkIf cfg.enable {
    modules.packages = {
      core.enable = true;
      desktop.enable = lib.mkDefault false;
    };
  };
}
