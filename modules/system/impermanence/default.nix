{ lib, config, username, inputs, ... }: {
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
      "/var/lib/AccountsService"
      "/var/lib/systemd"
      "/var/lib/btrfs"
      "/var/cache/btrfs"
      "/var/lib/docker" # If you use Docker
      "/var/lib/containers" # For Podman/containers
      "/var/lib/libvirt" # If you use VMs
      "/var/lib/fwupd" # For firmware updates
      "/var/lib/alsa"
      "/var/lib/chrony"
      "/var/lib/sysctl"

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
        user = "${username}";
        group = "users";
      }
    ];
    files = [
      "/etc/machine-id"
      "/etc/adjtime" # For hardware clock synchronization
      "/etc/shadow" # System passwords
      "/etc/passwd" # User account information
      "/etc/group" # Group information
      "/etc/ssh/ssh_host_rsa_key"
      "/etc/ssh/ssh_host_rsa_key.pub"
      "/etc/ssh/ssh_host_ed25519_key"
      "/etc/ssh/ssh_host_ed25519_key.pub"
      "/etc/subuid" # For container user mappings
      "/etc/subgid" # For container group mappings
      "/etc/fstab" # Static filesystem info
      "/etc/crypttab" # For encrypted devices
      # Your SOPS secrets
    ] ++ (builtins.attrValues
      (builtins.mapAttrs (name: value: value.path) config.sops.secrets));
  };

  programs.fuse.userAllowOther = true;
}
