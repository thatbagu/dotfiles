{ config, lib, pkgs, ... }:

with lib;
let cfg = config.modules.nixvim.plugins.firenvim;
in {
  options.modules.nixvim.plugins.firenvim = {
    enable = mkEnableOption "firenvim";
  };

  config = mkIf cfg.enable {
    programs.nixvim = {
      extraPlugins = with pkgs.vimPlugins; [ firenvim ];

      extraConfigLua = ''
        -- Firenvim configuration
        vim.g.firenvim_config = {
          globalSettings = { alt = "all" },
          localSettings = {
            [".*"] = {
              cmdline = "neovim",
              content = "text",
              priority = 0,
              selector = "textarea",
              takeover = "always"
            }
          }
        }

        -- Different settings when running in Firenvim
        if vim.g.started_by_firenvim == true then
          vim.o.laststatus = 0
        else
          vim.o.laststatus = 2
        end

        -- Auto-install firenvim
        if vim.fn.exists('g:started_by_firenvim') == 0 and vim.fn.exists('g:firenvim_installed') == 0 then
          vim.cmd[[call firenvim#install(0)]]
        end
      '';
    };
  };
}
