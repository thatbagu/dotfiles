{ ... }: {
  imports = [ ../../modules/system/disko ];

  diskConfig = {
    device = "/dev/nvme0n1";
    espSize = "500M";
  };
}
