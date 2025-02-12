{ lib, config, ... }: {
  options = { leap.enable = lib.mkEnableOption "Enable leap module"; };
  config = lib.mkIf config.leap.enable { plugins.leap = { enable = true; }; };
}
