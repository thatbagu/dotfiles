{ pkgs, lib, config, ... }:

with lib;
let
  cfg = config.modules.zellij;
  shellAliases = { "zj" = "zellij"; };

in {
  options.modules.zellij = { enable = mkEnableOption "zellij"; };
  config = mkIf cfg.enable {
    programs.zellij.enable = true;

    home.shellAliases = shellAliases;
    programs.fish.shellAliases = shellAliases;

    stylix.targets.zellij.enable = false;
    xdg.configFile."zellij/config.kdl".source = ./config.kdl;
    xdg.configFile."zellij/themes/stylix.kdl".source = ./theme.kdl;
    xdg.configFile."zellij/layouts/transparent.kdl".source = ./layouts/transparent.kdl;
  };
}
