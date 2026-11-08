{ ... }: {
  imports = [
    ../../modules/system/configuration.nix
    # Genkan dev prerequisites (Docker, kvm/docker groups, vhost_vsock); see ~/Code/genkan/dev/nixos/APPLY.md
    ../../modules/system/genkan-dev.nix
  ];

  config = {
    diskConfig = {
      device = "/dev/nvme0n1";
      espSize = "500M";
    };
    modules = {
      sys-packages.enable = true;
      steam.enable = true;
      stylix.enable = true;
      # unifi.enable = true;
      sops.enable = true;
      desktop.enable = true;
      wireguard.enable = true;
      wireguard.homelab.enable = true;
    };
    genkan.dev = {
      enable = true;
      user = "egor";
    };
  };
}
