{ pkgs, lib, config, inputs, ... }:
with lib;
let
  cfg = config.modules.nixvim;
  nixvim_config = import ./config;
in {
  options.modules.nixvim = { enable = mkEnableOption "nixvim"; };

  config = mkIf cfg.enable {

    programs.nixvim = {
      enable = true;
      imports = [ nixvim_config ];
      nixpkgs.config.allowUnfree = true;
      nixpkgs.overlays = [
        (final: prev: {
          vimPlugins = prev.vimPlugins // {
            nvim-lspconfig = prev.vimPlugins.nvim-lspconfig.overrideAttrs (old: {
              postPatch = (old.postPatch or "") + ''
                substituteInPlace plugin/lspconfig.lua \
                  --replace-warn 'client.is_stopped()' 'client:is_stopped()'
              '';
            });
          };
        })
      ];

      # # Disable other colorschemes first
      # colorschemes.catppuccin.enable = lib.mkForce false;
      # colorschemes.nord.enable = false;
      #
      # # Enable and configure base16
      # colorschemes.base16 = {
      #     enable = true;
      #     colorscheme = "mountain";
      #     setUpBar = true;
      # };
    };
  };
}
