{ pkgs, lib, inputs, username, ... }:

let gitRepoUrl = "https://github.com/Jahysama/dotfiles.git";
in {
  imports = [
    "${inputs.nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
    ./hardware-configuration.nix
  ];

  nixpkgs = {
    hostPlatform = lib.mkDefault "x86_64-linux";
    config.allowUnfree = true;
  };

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  environment.systemPackages = with pkgs; [
    git
    vim
    age
    sops
    gum

    # Script to sync with the original Git repository
    (writeShellScriptBin "sync-dotfiles-repo" ''
      #!/usr/bin/env bash
      set -euo pipefail

      TARGET_DIR="$1"
      GIT_REPO_URL="$2"

      if [ -z "$TARGET_DIR" ] || [ -z "$GIT_REPO_URL" ]; then
        echo "Usage: sync-dotfiles-repo <target-directory> <git-repo-url>"
        echo "Example: sync-dotfiles-repo ~/.dotfiles https://github.com/yourusername/dotfiles.git"
        exit 1
      fi

      # Ensure target directory exists
      mkdir -p "$TARGET_DIR"

      # Check if directory is empty
      if [ "$(ls -A "$TARGET_DIR")" ]; then
        echo "Target directory is not empty. Backing it up..."
        BACKUP_DIR="$TARGET_DIR-backup-$(date +%Y%m%d-%H%M%S)"
        mv "$TARGET_DIR" "$BACKUP_DIR"
        mkdir -p "$TARGET_DIR"
      fi

      # Clone the repository
      echo "Cloning repository from $GIT_REPO_URL to $TARGET_DIR..."
      git clone "$GIT_REPO_URL" "$TARGET_DIR"

      echo "Git repository successfully cloned to $TARGET_DIR"
    '')

    (writeShellScriptBin "nix_installer" ''
      #!/usr/bin/env bash
      set -euo pipefail

      if [ "$(id -u)" -eq 0 ]; then
        echo "ERROR! $(basename "$0") should be run as a regular user"
        exit 1
      fi

      # Get username from the target host configuration
      echo "Available hosts:"
      FULL_HOST_PATH=$(find /etc/nixos/hosts -name "system.nix" -not -path "*/iso/*" | 
                       sed 's|/etc/nixos/hosts/||' | 
                       sed 's|/system.nix||' |
                       gum choose)

      # Extract just the hostname (last part of the path)
      TARGET_HOST=$(basename "$FULL_HOST_PATH")

      echo "Please enter username:"
      TARGET_USER=$(gum input --placeholder "username")

      # Verify we got a reasonable username
      if [ -z "$TARGET_USER" ]; then
        echo "Please enter username:"
        TARGET_USER=$(gum input --placeholder "username")
      fi

      echo "Installing for user: $TARGET_USER"
      echo "Using host configuration: $TARGET_HOST (from $FULL_HOST_PATH)"
      # Select target disk
      echo "Available disks:"
      TARGET_DISK=$(lsblk -d -n -l -o NAME,SIZE | gum choose | cut -d' ' -f1)

      gum confirm --default=false \
        "WARNING!!!! This will ERASE ALL DATA on /dev/$TARGET_DISK. Continue?"

      echo "Installing NixOS on /dev/$TARGET_DISK with host config $TARGET_HOST"

      # Apply disko configuration
      echo "Applying disk configuration..."
      sudo nix run github:nix-community/disko -- \
        --mode disko \
        --flake "/etc/nixos#$TARGET_HOST" \
        --arg diskConfig.device "/dev/$TARGET_DISK"

      # First, copy config to target system's /etc/nixos for installation
      sudo mkdir -p /mnt/etc/nixos
      sudo cp -r /etc/nixos/* /mnt/etc/nixos/
      sudo cp -r /etc/nixos/.* /mnt/etc/nixos/ 2>/dev/null || true

      # Set up SOPS age key in persistent storage
      sudo mkdir -p "/mnt/persist/etc/sops-nix"
      sudo cp /etc/sops/age/keys.txt "/mnt/persist/etc/sops-nix/keys.txt"
      sudo chmod 600 "/mnt/persist/etc/sops-nix/keys.txt"

      # Install NixOS
      echo "Installing NixOS..."
      sudo nixos-install --flake "/mnt/etc/nixos#$TARGET_HOST" --no-root-passwd

      # Generate hardware config without filesystem definitions
      sudo nixos-generate-config --no-filesystems --dir /tmp

      # Set up dotfiles in persistent storage
      echo "Setting up dotfiles in persistent storage..."
      sudo mkdir -p "/mnt/persist/home/$TARGET_USER/.dotfiles"
      sudo cp -r /mnt/etc/nixos/* "/mnt/persist/home/$TARGET_USER/.dotfiles/"
      sudo cp -r /mnt/etc/nixos/.* "/mnt/persist/home/$TARGET_USER/.dotfiles/" 2>/dev/null || true

      # Copy the generated hardware config (without filesystems) to the target location
      sudo cp /tmp/hardware-configuration.nix "/mnt/persist/home/$TARGET_USER/.dotfiles/hosts/$FULL_HOST_PATH/"
      # Clean up temporary files
      sudo rm /tmp/configuration.nix

      # Set proper ownership
      sudo chown -R 1000:1000 "/mnt/persist/home/$TARGET_USER/.dotfiles"

      # Create required directories and symlinks
      sudo mkdir -p "/mnt/home/$TARGET_USER"
      sudo ln -sf "/persist/home/$TARGET_USER/.dotfiles" "/mnt/home/$TARGET_USER/.dotfiles"

      # Remove original /etc/nixos and create symlink
      sudo rm -rf /mnt/etc/nixos
      sudo ln -sf "/persist/home/$TARGET_USER/.dotfiles" /mnt/etc/nixos

      # Use the predefined Git Repository URL
      GIT_REPO_URL="${gitRepoUrl}"

      if [ -n "$GIT_REPO_URL" ]; then
        echo "Syncing with the Git repository..."
        sync-dotfiles-repo "/mnt/persist/home/$TARGET_USER/.dotfiles" "$GIT_REPO_URL"
        
        # Fix permissions after sync
        sudo chown -R 1000:1000 "/mnt/persist/home/$TARGET_USER/.dotfiles"
      fi

      echo "Installation complete! Your configuration is in /persist/home/$TARGET_USER/.dotfiles"
      echo "Symlinks created in ~/.dotfiles and /etc/nixos"
      echo "SOPS age key has been copied to both system and user locations"
      echo "Hardware configuration has been preserved"
    '')
  ];

  services = {
    qemuGuest.enable = true;
    openssh.settings.PermitRootLogin = lib.mkForce "yes";
  };

  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    supportedFilesystems =
      lib.mkForce [ "btrfs" "reiserfs" "vfat" "f2fs" "xfs" "ntfs" "cifs" ];
  };

  systemd = {
    services.sshd.wantedBy = pkgs.lib.mkForce [ "multi-user.target" ];
  };

  # Simple activation script that only copies the regular files
  system.activationScripts.installerCustomization = {
    text = ''
      # Copy regular configuration files
      mkdir -p /etc/nixos/{modules,hosts,pics}
      cp -r ${../../modules}/* /etc/nixos/modules/
      cp -r ${../../hosts}/* /etc/nixos/hosts/
      cp -r ${../../pics}/* /etc/nixos/pics/
      cp ${../../flake.nix} /etc/nixos/flake.nix
      cp ${../../flake.lock} /etc/nixos/flake.lock
      cp ${../../.sops.yaml} /etc/nixos/.sops.yaml

      # SOPS setup
      mkdir -p /etc/sops/age
      cp ${~/.config/sops/age/keys.txt} /etc/sops/age/keys.txt
      chmod 600 /etc/sops/age/keys.txt
    '';
  };

  users.users.nixos = {
    password = "nixos";
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
  };

  # Enable networking
  networking = {
    networkmanager.enable = true;
    wireless.enable = false;
  };

  # Set your time zone
  time.timeZone = "Asia/Almaty";

  # Select internationalisation properties
  i18n.defaultLocale = "en_US.UTF-8";

  console = { keyMap = "us"; };
}
