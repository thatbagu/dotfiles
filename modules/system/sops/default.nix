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
      secrets = {
        antropic_key = { owner = "${username}"; };
        github_token = { owner = "${username}"; };
        git_email = { owner = "${username}"; };
        cloudflare_email = { owner = "${username}"; };
        k3s_token = { owner = "${username}"; };
        pihole_password = { owner = "${username}"; };
        cloudflare_token = { owner = "${username}"; };

        # wireguard
        egor_main_wg_public_key = { owner = "${username}"; };
        egor_main_wg_private_key = { owner = "${username}"; };

        user_password = { neededForUsers = true; };

        private_ssh_key = {
          path = "/home/${username}/.ssh/ssh_host_ed25519_key";
          mode = "0600";
          owner = "${username}";
        };
      };
    };
  };
}
