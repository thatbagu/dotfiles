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
