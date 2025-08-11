{ ... }: {
  imports = [ ../../modules/system/configuration.nix ];

  config = {
    diskConfig = {
      device = "/dev/sdb";
      espSize = "500M";
    };
    modules = {
      sys-packages.enable = true;
      steam.enable = true;
      stylix = {
        enable = true;
        scale = 0.8; # Set UI scale to 80%
      };
      sops.enable = true;
      desktop.enable = true;
    };
  };
}
