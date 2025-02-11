{ pkgs, lib, config, ... }:

with lib;
let 
  cfg = config.modules.zellij;
  shellAliases = {
    "zj" = "zellij";
  };

in {
    options.modules.zellij = { enable = mkEnableOption "zellij"; };
    config = mkIf cfg.enable {
      programs.zellij.enable = true;

      home.shellAliases = shellAliases;
      programs.nushell.shellAliases = shellAliases;

      xdg.configFile."zellij/config.kdl".source = ./config.kdl;
    };
}
