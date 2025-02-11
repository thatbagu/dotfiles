{ pkgs, lib, config, username, ... }:

with lib;
let cfg = config.modules.sops;
in {
  options.modules.sops = { enable = mkEnableOption "sops"; };

  config = mkIf cfg.enable {
    sops = {
      age.keyFile = "/home/${username}/.config/sops/age/keys.txt";
      defaultSopsFile = ./secrets.yaml;
      defaultSopsFormat = "yaml";

      secrets.antropic_key = { owner = "${username}"; };
      secrets.github_token = { owner = "${username}"; };
    };
  };
}
