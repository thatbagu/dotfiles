# NixOS module: system-level prerequisites for developing and testing Genkan
# (Phase 2: docker, srt and microvm backends).
#
# Userland tooling (Go, linters, srt, cloud-hypervisor, qemu, virtiofsd, ...)
# lives in the repo's `nix develop` shell, not here. This module only holds
# what needs root: the Docker daemon, group membership, kernel modules and Nix
# settings. See dev/nixos/APPLY.md for how to import it.
#
# Usage (inside your NixOS configuration):
#   imports = [ /path/to/genkan/dev/nixos/genkan-dev.nix ];
#   genkan.dev.enable = true;
#   genkan.dev.user = "egor";
{ config, lib, ... }:

let
  cfg = config.genkan.dev;
in
{
  options.genkan.dev = {
    enable = lib.mkEnableOption "system prerequisites for Genkan development";

    user = lib.mkOption {
      type = lib.types.str;
      example = "egor";
      description = "Login user who runs `nix develop`, the test suites and the backends.";
    };

    docker = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Run the Docker daemon and add the user to the `docker` group, so the
        `docker` backend and `go test -tags docker` run against real Docker
        (Phase 1 only ever ran against rootless Podman).
      '';
    };

    nestedVirtualization = lib.mkOption {
      type = lib.types.enum [
        "none"
        "intel"
        "amd"
      ];
      default = "none";
      description = ''
        Only needed when THIS machine is itself a VM that should run the
        `microvm` backend (KVM inside KVM), or when you want to run Genkan's
        microVM tests inside another VM. Bare-metal hosts leave it at "none".
        The setting takes effect on the *outer* host's KVM module.
      '';
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        # `nix develop`, `nix build <flake>` (env.kind=nix) and the microvm.nix
        # runners (`nix build .#nixosConfigurations.<vm>.config.microvm.declaredRunner`)
        # all need the new CLI and flakes. List options merge, so this is a
        # no-op if they are already enabled elsewhere.
        nix.settings.experimental-features = [
          "nix-command"
          "flakes"
        ];

        # microvm backend (M10): the VM has no NIC; its only channel to the
        # gateway is vsock.
        #  - cloud-hypervisor implements vsock in userspace (hybrid vsock over
        #    a Unix socket) and needs nothing from the host kernel beyond KVM.
        #  - qemu uses the kernel's vhost-vsock device, which needs the
        #    `vhost_vsock` module on the host. systemd creates the
        #    /dev/vhost-vsock static node and loads the module on first open,
        #    but loading it at boot makes `CheckAvailable` deterministic and
        #    lets host processes bind AF_VSOCK listeners before any VM starts.
        boot.kernelModules = [ "vhost_vsock" ];

        # /dev/kvm access. systemd's default udev rule already makes /dev/kvm
        # mode 0666, so group membership is belt and braces. It also lets
        # microvm.nix's virtiofsd `--socket-group=kvm` default work for other
        # guests (Genkan's own guest module disables that flag, because it
        # fails with EPERM for users outside `kvm`).
        users.users.${cfg.user}.extraGroups = [ "kvm" ];

        # No microvm.nix *host* module (`microvm.nixosModules.host`): Genkan
        # starts each microVM itself from its runner package, as the invoking
        # user, with vsock only. It needs no systemd-managed VMs, no tap
        # devices, no bridges and no /var/lib/microvms state.
      }

      (lib.mkIf cfg.docker {
        # Docker daemon for the `docker` backend and the docker-tagged tests.
        virtualisation.docker.enable = true;

        # Membership in `docker` is root-equivalent (the daemon socket can
        # mount / into a container). That is the accepted trade-off on a
        # single-user dev box; on shared machines prefer
        # `virtualisation.docker.rootless.enable` (and set
        # GENKAN_CONTAINER_CLI=docker with DOCKER_HOST pointing at the rootless
        # socket), or keep using rootless Podman from the dev shell.
        users.users.${cfg.user}.extraGroups = [ "docker" ];

        # Genkan tests create many short-lived images, networks and
        # containers (all labelled and removed on teardown, but interrupted
        # runs and image builds leave layers). Weekly prune keeps the disk in
        # check without touching running containers.
        virtualisation.docker.autoPrune = {
          enable = true;
          dates = "weekly";
        };
      })

      (lib.mkIf (cfg.nestedVirtualization == "intel") {
        # Let VMs on this host run KVM themselves.
        boot.extraModprobeConfig = "options kvm_intel nested=1";
      })

      (lib.mkIf (cfg.nestedVirtualization == "amd") {
        # Let VMs on this host run KVM themselves.
        boot.extraModprobeConfig = "options kvm_amd nested=1";
      })
    ]
  );
}
