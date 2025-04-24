{ pkgs, lib, config, username, ... }:

with lib;
let cfg = config.modules.sops;
in {
  options.modules.sops = { enable = mkEnableOption "sops"; };

  config = mkIf cfg.enable {
    sops = {
      age.keyFile = "/persist/etc/sops-nix/keys.txt";
      defaultSopsFile = ./secrets.yaml;
      defaultSopsFormat = "yaml";

      secrets.antropic_key = { owner = "${username}"; };
      secrets.github_token = { owner = "${username}"; };
      secrets.k3s_token = { owner = "${username}"; };
      secrets.pihole_password = { owner = "${username}"; };
      secrets.cloudflare_token = { owner = "${username}"; };

      secrets.user_password = { neededForUsers = true; };

      secrets.private_ssh_key = {
        path = "/home/${username}/.ssh/ssh_host_ed25519_key";
        mode = "0600";
        owner = "${username}";
      };
    };
  };
}
