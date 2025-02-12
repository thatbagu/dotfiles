{ lib, config, pkgs, ... }: {
  options = {
    venv-selector.enable = lib.mkEnableOption "Enable venv-selector module";
  };

  config = lib.mkIf config.venv-selector.enable {
    extraPlugins = with pkgs.vimUtils;
      [
        (buildVimPlugin {
          pname = "venv-selector.nvim";
          version = "2024-03-14";
          src = pkgs.fetchFromGitHub {
            owner = "linux-cultist";
            repo = "venv-selector.nvim";
            rev = "e82594274bf7b54387f9a2abe65f74909ac66e97";
            sha256 = "sha256-AyxITaKoeM+l+RbFp2UWy0zVrxrIxy8S/oDJsEr/VDQ=";
          };
        })
      ];

    extraConfigLua = ''
      require('venv-selector').setup({
        name = {"venv", ".venv"},
        auto_refresh = false,
        search_venv_managers = true,
        search_workspace = true,
        parents = 2,
        notify_user_on_activate = true,
        dap_enabled = true
      })

      vim.keymap.set('n', '<leader>vs', '<cmd>VenvSelect<cr>')
      vim.keymap.set('n', '<leader>vc', '<cmd>VenvSelectCached<cr>')
    '';

    # Dependencies required by venv-selector
    extraPackages = with pkgs; [ fd ];
  };
}

