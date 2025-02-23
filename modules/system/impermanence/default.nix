{ lib, config, username, inputs, ... }: {
  fileSystems."/persist".neededForBoot = true;
  environment.persistence."/persist" = {
    hideMounts = true;
    directories = [
      # Essential system directories
      "/etc/nixos"
      "/var/log"
      "/var/lib/nixos"
      "/var/lib/systemd/coredump"

      # Network configuration
      "/etc/NetworkManager/system-connections"
      "/var/lib/NetworkManager"

      # System services
      "/var/lib/systemd"
      "/var/lib/AccountsService"
      "/var/lib/bluetooth"

      # File system
      "/var/lib/btrfs"
      "/var/cache/btrfs"

      # Container/VM support
      "/var/lib/docker"
      "/var/lib/containers"
      "/var/lib/libvirt"

      # Audio
      {
        directory = "/var/lib/pipewire";
        user = "${username}";
        group = "users";
        mode = "u=rwx,g=rx,o=";
      }
      "/var/lib/alsa"

      # System configuration
      "/var/lib/chrony"
      "/var/lib/sysctl"

      # User-specific system directories
      {
        directory = "/var/lib/firefox";
        user = "${username}";
        group = "users";
        mode = "u=rwx,g=rx,o=";
      }
      {
        directory = "/var/lib/unifi";
        user = "${username}";
        group = "unifi";
      }
    ];
    files = [
      # System identification
      "/etc/machine-id"

      # System configuration
      "/etc/adjtime"

      # # Security and access control
      # "/etc/shadow"
      # "/etc/passwd"
      # "/etc/group"

      # SSH host keys
      "/etc/ssh/ssh_host_rsa_key"
      "/etc/ssh/ssh_host_rsa_key.pub"
      "/etc/ssh/ssh_host_ed25519_key"
      "/etc/ssh/ssh_host_ed25519_key.pub"

      # # Container configuration
      # "/etc/subuid"
      # "/etc/subgid"

      # # Mount configuration
      # "/etc/fstab"
      # "/etc/crypttab"
    ];

    users.${username} = {
      directories = [
        # User data
        "Code"
        "Downloads"
        "Music"
        "Pictures"
        "Documents"
        "Videos"

        # Secure directories
        {
          directory = ".gnupg";
          mode = "0700";
        }
        {
          directory = ".ssh";
          mode = "0700";
        }
        {
          directory = ".local/share/keyrings";
          mode = "0700";
        }
        {
          directory = ".config/sops";
          mode = "0700";
        }

        # Development
        ".local/share/direnv"

        # Dots
        ".config"
        ".local"
        ".dotfiles"

        # Browser data
        ".mozilla"
        ".cache/mozilla"
      ];
    };
  };
  programs.fuse.userAllowOther = true;
}
