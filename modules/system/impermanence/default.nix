# modules/system/impermanence/default.nix
{ lib, config, username, ... }: {
  fileSystems."/persist".neededForBoot = true;

  environment.persistence."/persist/system" = {
    hideMounts = true;
    directories = [
      "/etc/nixos"
      "/var/log"
      "/var/lib/bluetooth"
      "/var/lib/nixos"
      "/var/lib/systemd/coredump"
      "/etc/NetworkManager/system-connections"
      "/var/lib/NetworkManager"
      # For your Firefox add-ons and Stylix themes
      {
        directory = "/var/lib/firefox";
        user = "${username}";
        group = "users";
      }
      {
        directory = "/var/lib/stylix";
        user = "${username}";
        group = "users";
      }
      # For your Unifi setup
      {
        directory = "/var/lib/unifi";
        user = "${username}";
        group = "unifi";
      }
      # For your pipewire setup
      {
        directory = "/var/lib/pipewire";
        user = "egor";
        group = "users";
      }
    ];
    files = [
      "/etc/machine-id"
      "/etc/adjtime" # For hardware clock synchronization
      # Your SOPS secrets
      config.sops.secrets.antropic_key.path
      config.sops.secrets.github_token.path
    ];
  };

  programs.fuse.userAllowOther = true;
}
