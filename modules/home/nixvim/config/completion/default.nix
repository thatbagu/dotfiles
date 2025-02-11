{
  lib,
  config,
  ...
}:
{
  imports = [
    ./cmp.nix
    ./copilot.nix
  ];

  options = {
    completion.enable = lib.mkEnableOption "Enable completion module";
  };
  config = lib.mkIf config.completion.enable {
    cmp.enable = lib.mkDefault true;
    avante = {
      enable = lib.mkDefault true;
      position = "right";
      width = 30;
    };
  };
}
