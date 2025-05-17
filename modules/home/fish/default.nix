{ pkgs, lib, config, ... }:
with lib;
let cfg = config.modules.fish;
in {
    options.modules.fish = { enable = mkEnableOption "fish"; };
    config = mkIf cfg.enable {
        programs.fish = {
            enable = true;
            interactiveShellInit = ''
              set fish_greeting # Disable greeting
            '';
            shellAliases = {
              ls = "ls --color=auto";
              ll = "ls -la";
              ".." = "cd ..";
              "..." = "cd ../..";
              "...." = "cd ../../..";
              "....." = "cd ../../../..";
              vi = "nvim";
              vim = "nvim";
            };
        };
    };
}
