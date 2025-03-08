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
        master = false;
        masterHostname = "meowth";
      };
      sops.enable = true;
    };
  };
}
