{
  lib,
  config,
  pkgs,
  ...
}:
{
  options = {
    friendly-snippets.enable = lib.mkEnableOption "Enable friendly-snippets module";
  };
  config = lib.mkIf config.friendly-snippets.enable {
    extraPlugins = with pkgs.vimPlugins; [
      friendly-snippets
    ];

    extraConfigLua = ''
      -- Load friendly-snippets for LuaSnip
      require("luasnip.loaders.from_vscode").lazy_load()
    '';
  };
}
