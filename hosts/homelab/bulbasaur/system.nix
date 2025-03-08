{ ... }: {
  imports = [ ../../../modules/system/configuration.nix ];

  diskConfig = {
    device = "/dev/sda";
    espSize = "500M";
  };

  config.modules = {
    sys-packages.enable = true;
    k3s = {
      enable = true;
      master = false;
      masterHostname = "meowth";
    };
    sops.enable = true;
  };
}
