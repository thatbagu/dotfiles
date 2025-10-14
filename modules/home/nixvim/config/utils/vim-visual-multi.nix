{ lib, config, pkgs, ... }: {
  options = {
    vim-visual-multi.enable =
      lib.mkEnableOption "Enable vim-visual-multi module";
  };

  config = lib.mkIf config.vim-visual-multi.enable {
    extraPlugins = with pkgs.vimPlugins; [ vim-visual-multi ];

    # Optional: Custom configuration
    extraConfigLua = ''
      -- vim-visual-multi settings
      vim.g.VM_theme = 'iceblue'
      vim.g.VM_mouse_mappings = 1

      -- Optional: Customize default mappings
      -- vim.g.VM_maps = {
      --   ['Find Under'] = '<C-n>',
      --   ['Find Subword Under'] = '<C-n>',
      -- }
    '';
  };
}

