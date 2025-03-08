{ ... }: {
  imports = [ ../../../modules/system/configuration.nix ];

  config = {
    diskConfig = {
      device = "/dev/sda";
      espSize = "500M";
    };

    modules = {
      sys-packages.enable = true;
      k3s = {
        enable = true;
        master = true;
      };
      k8s.enable = true;
      sops.enable = true;
    };
  };
}
