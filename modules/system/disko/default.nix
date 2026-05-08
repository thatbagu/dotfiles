{ config, lib, ... }:
let inherit (lib) types mkOption;
in {
  options.diskConfig = {
    device = mkOption {
      type = types.str;
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
              boot = {
                name = "boot";
                size = "1M";
                type = "EF02";
              };
              ESP = {
                name = "ESP";
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
                name = "root";
                size = "100%";
                content = {
                  type = "lvm_pv";
                  vg = "root_vg";
                };
              };
            };
          };
        };
      };
      lvm_vg = {
        root_vg = {
          type = "lvm_vg";
          lvs = {
            root = {
              size = "100%FREE";
              content = {
                type = "btrfs";
                extraArgs = [ "-f" ];
                subvolumes = {
                  "/root" = { mountpoint = "/"; };
                  "/persist" = {
                    mountOptions = [ "subvol=persist" "noatime" ];
                    mountpoint = "/persist";
                  };
                  "/nix" = {
                    mountOptions = [ "subvol=nix" "noatime" ];
                    mountpoint = "/nix";
                  };
                };
              };
            };
          };
        };
      };
    };
    boot.initrd.systemd.services.rollback = {
      description = "Rollback BTRFS root subvolume";
      wantedBy = [ "initrd.target" ];
      after = [ "dev-root_vg-root.device" ];
      before = [ "sysroot.mount" ];
      unitConfig.DefaultDependencies = "no";
      serviceConfig.Type = "oneshot";
      script = ''
        mkdir /btrfs_tmp
        mount /dev/root_vg/root /btrfs_tmp
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
  };
}
