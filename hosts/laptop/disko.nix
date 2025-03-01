{ device ? null, ... }: {
  imports = [ ../../modules/system/disko ];

  diskConfig = {
    device = "/dev/sdb";
    espSize = "500M";
  };
}
