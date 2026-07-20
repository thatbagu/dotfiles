{ lib, config, ... }:
{
  options = {
    noice.enable = lib.mkEnableOption "Enable noice module";
  };
  config = lib.mkIf config.noice.enable {
    plugins.noice = {
      enable = true;
    };
  };
}
