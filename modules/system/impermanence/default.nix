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
      "/var/lib/kubelet"
      "/var/lib/rancher/k3s"
      "/var/lib/csi"
      {
        directory = "/var/lib/longhorn";
        mode = "0700";
      }
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
        "Games"
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
        ".claude"
        ".espup"
        ".rustup"

        # Browser data
        ".mozilla"
        ".cache/mozilla"
      ];
    };
  };
  programs.fuse.userAllowOther = true;
}
