{
  lib,
  config,
  ...
}:
{
  imports = [
    ./luasnip.nix
    ./friendly-snippets.nix
  ];

  options = {
    snippets.enable = lib.mkEnableOption "Enable snippets module";
  };
  config = lib.mkIf config.snippets.enable {
    luasnip.enable = lib.mkDefault true;
    friendly-snippets.enable = lib.mkDefault true;
  };
}
