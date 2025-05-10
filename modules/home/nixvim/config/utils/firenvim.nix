{ lib, config, pkgs, ... }: {
  options = { firenvim.enable = lib.mkEnableOption "Enable firenvim module"; };

  config = lib.mkIf config.firenvim.enable {
    extraPlugins = with pkgs.vimPlugins; [ firenvim ];

    extraConfigLua = ''
      -- Basic Firenvim configuration
      vim.g.firenvim_config = {
        globalSettings = { alt = "all" },
        localSettings = {
          [".*"] = {
            cmdline = "neovim",
            content = "text",
            takeover = "always"
          }
        }
      }

      -- Different settings when running in Firenvim
      if vim.g.started_by_firenvim == true then
        vim.opt.laststatus = 0
      end
    '';
  };
}
