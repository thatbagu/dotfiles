{ config, lib, ... }:
let inherit (lib) types mkOption;
in {
  options.diskConfig = {
    device = mkOption {
      type = types.str;
      example = "/dev/nvme0n1";
      description = "The disk device to use";
    };

    espSize = mkOption {
      type = types.str;
      default = "500M";
      description = "Size of the EFI system partition";
    };
  };

  config = {
    disko.devices = {
      disk = {
        main = {
          type = "disk";
          device = config.diskConfig.device;
          content = {
            type = "gpt";
            partitions = {
              ESP = {
                size = config.diskConfig.espSize;
                type = "EF00";
                content = {
                  type = "filesystem";
                  format = "vfat";
                  mountpoint = "/boot";
                  mountOptions = [
                    "fmask=0022"
                    "dmask=0022"
                    "codepage=437"
                    "iocharset=iso8859-1"
                    "shortname=mixed"
                    "errors=remount-ro"
                  ];
                };
              };
              root = {
                size = "100%";
                content = {
                  type = "btrfs";
                  extraArgs = [ "-f" ];
                  subvolumes = {
                    "/root" = {
                      mountpoint = "/";
                      mountOptions = [ "compress=zstd" "noatime" ];
                    };
                    "/home" = {
                      mountpoint = "/home";
                      mountOptions = [ "compress=zstd" "noatime" ];
                    };
                    "/nix" = {
                      mountpoint = "/nix";
                      mountOptions = [ "compress=zstd" "noatime" ];
                    };
                    "/persist" = {
                      mountpoint = "/persist";
                      mountOptions = [ "compress=zstd" "noatime" ];
                    };
                  };
                };
              };
            };
          };
        };
      };
    };

    boot.initrd.postDeviceCommands = lib.mkAfter ''
      mkdir -p /btrfs_tmp
      mount -o subvol=/ ${config.diskConfig.device}-part2 /btrfs_tmp

      # Create persist directory if it doesn't exist
      mkdir -p /btrfs_tmp/persist

      # Handle root subvolume rotation
      if [[ -e /btrfs_tmp/root ]]; then
        mkdir -p /btrfs_tmp/old_roots
        timestamp=$(date --date="@$(stat -c %Y /btrfs_tmp/root)" "+%Y-%m-%-d_%H:%M:%S")
        mv /btrfs_tmp/root "/btrfs_tmp/old_roots/$timestamp"
      fi

      # Cleanup old snapshots
      delete_subvolume_recursively() {
        IFS=$'\n'
        for i in $(btrfs subvolume list -o "$1" | cut -f 9- -d ' '); do
          delete_subvolume_recursively "/btrfs_tmp/$i"
        done
        btrfs subvolume delete "$1"
      }

      for i in $(find /btrfs_tmp/old_roots/ -maxdepth 1 -mtime +30); do
        delete_subvolume_recursively "$i"
      done

      # Create new root subvolume
      btrfs subvolume create /btrfs_tmp/root

      # Ensure /persist exists in new root
      mkdir -p /btrfs_tmp/root/persist
      mount --bind /btrfs_tmp/persist /btrfs_tmp/root/persist

      # Cleanup
      umount /btrfs_tmp/root/persist
      umount /btrfs_tmp
    '';
  };
}
