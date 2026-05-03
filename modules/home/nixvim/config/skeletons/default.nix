{ lib, config, ... }: {
  imports = [
    ./esqueleto.nix
  ];

  options = { skeletons.enable = lib.mkEnableOption "Enable skeletons module"; };
  config = lib.mkIf config.skeletons.enable {
    # Temporarily disabled due to require check failures
    esqueleto.enable = lib.mkDefault false;
  };
}
