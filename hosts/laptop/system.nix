{ ... }: {
  imports = [ ../../modules/system/configuration.nix ];

  diskConfig = {
    device = "/dev/sdb";
    espSize = "500M";
  };

  config.modules = {
    sys-packages.enable = true;
    steam.enable = true;
    stylix.enable = true;
    sops.enable = true;
    desktop.enable = true;
  };
}
