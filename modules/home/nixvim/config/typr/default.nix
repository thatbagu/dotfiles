{ lib, config, ... }: {
  options.typr = { enable = lib.mkEnableOption "typr"; };

  config = lib.mkIf config.typr.enable {
    plugins = {
      typr = {
        enable = true;
        dependencies = [ "nvzone/volt" ];
      };
    };
  };
}

