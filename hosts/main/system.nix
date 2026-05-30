{ ... }: {
  imports = [ ../../modules/system/configuration.nix ];

  config = {
    networking.hosts = {
      "192.168.1.77"  = [ "meowth" ];
      "192.168.1.131" = [ "psyduck" ];
      "192.168.1.129" = [ "bulbasaur" ];
    };

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
    };
  };
}
