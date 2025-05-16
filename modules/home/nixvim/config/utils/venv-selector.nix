{ lib, config, pkgs, ... }: {
  options = {
    venv-selector.enable = lib.mkEnableOption "Enable venv-selector module";
  };

  config = lib.mkIf config.venv-selector.enable {
    extraPlugins = with pkgs.vimUtils;
      [
        (buildVimPlugin {
          pname = "venv-selector.nvim";
          version = "2025-03-22";
          src = pkgs.fetchFromGitHub {
            owner = "linux-cultist";
            repo = "venv-selector.nvim";
            rev = "regexp"; # Use latest main branch
            sha256 =
              "sha256-ogd4T+mIbb86qFUbDczzDra8yWm/bwKmYCRGYCJz6fM="; # Nix will tell us the correct hash
          };
          doCheck = false;
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
