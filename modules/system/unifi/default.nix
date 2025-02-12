{ pkgs, lib, config, ... }:

with lib;
let cfg = config.modules.unifi;
in {
  options.modules.unifi = { enable = mkEnableOption "unifi"; };

  config = mkIf cfg.enable {
    services.unifi = {
      enable = true;
      openFirewall =
        true; # Enable if you want the firewall ports opened automatically
      unifiPackage = pkgs.unifi8;
      mongodbPackage = pkgs.mongodb-7_0;

      # Optional: Configure Java heap sizes if needed
      initialJavaHeapSize = 1024; # 1GB initial heap
      maximumJavaHeapSize = 4096; # 4GB maximum heap

      # Optional: Add any extra JVM options if needed
      extraJvmOptions = [ "-XX:+UseG1GC" "-XX:MaxGCPauseMillis=100" ];
    };

    # Ensure MongoDB service is enabled
    services.mongodb = {
      enable = true;
      package = pkgs.mongodb-7_0;
    };
  };
}
