{ lib, config, pkgs, ... }: {
  options = {
    multicursors.enable = lib.mkEnableOption "Enable multicursors module";
  };
  config = lib.mkIf config.multicursors.enable {
    extraPlugins = with pkgs.vimPlugins; [ hydra-nvim multicursors-nvim ];
    extraConfigLua = ''
      require('multicursors').setup({})
    '';
    keymaps = [{
      mode = [ "n" "v" ];
      key = "<leader>mc";
      action = "<cmd>MCstart<cr>";
      options = {
        silent = true;
        desc = "Multicursor start";
      };
    }];
  };
}
