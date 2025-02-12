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
      mkdir /btrfs_tmp
      mount -o subvol=/ ${config.diskConfig.device}-part2 /btrfs_tmp
      if [[ -e /btrfs_tmp/root ]]; then
          mkdir -p /btrfs_tmp/old_roots
          timestamp=$(date --date="@$(stat -c %Y /btrfs_tmp/root)" "+%Y-%m-%-d_%H:%M:%S")
          mv /btrfs_tmp/root "/btrfs_tmp/old_roots/$timestamp"
      fi

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
      btrfs subvolume create /btrfs_tmp/root
      umount /btrfs_tmp
    '';
  };
}
