{ device ? null, ... }: {
  imports = [ ../../../modules/system/disko ];

  diskConfig = {
    device = "/dev/sda";
    espSize = "500M";
  };
}
