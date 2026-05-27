{
  lib,
  config,
  ...
}:
{
  imports = [
    ./treesitter-nvim.nix
    ./nvim-lint.nix
    ./nvim-ufo.nix
  ];

  options = {
    languages.enable = lib.mkEnableOption "Enable languages module";
  };
  config = lib.mkIf config.languages.enable {
    treesitter-nvim.enable = lib.mkDefault true;
    nvim-lint.enable = lib.mkDefault true;
    nvim-ufo.enable = lib.mkDefault true;
  };
}
