{
  lib,
  config,
  pkgs,
  ...
}:
let
  templateDir = ./templates;
in
{
  options = {
    esqueleto.enable = lib.mkEnableOption "Enable esqueleto module";
  };
  config = lib.mkIf config.esqueleto.enable {
    extraPlugins = [
      (pkgs.vimUtils.buildVimPlugin {
        name = "esqueleto.nvim";
        src = pkgs.fetchFromGitHub {
          owner = "cvigilv";
          repo = "esqueleto.nvim";
          rev = "main";
          sha256 = "sha256-AeB4ZCoRVGTMLxku1/x+TI/LenIWryjK/PmrdwyUHKg=";
        };
      })
    ];

    # NOTE: xdg.configFile cannot be set from within nixvim module
    # If you need skeleton templates, copy them manually to ~/.config/nvim/skeletons/
    # or set them in your home-manager configuration
    # xdg.configFile = {
    #   "nvim/skeletons/python".source = "${templateDir}/python";
    #   "nvim/skeletons/go".source = "${templateDir}/go";
    #   "nvim/skeletons/rust".source = "${templateDir}/rust";
    #   "nvim/skeletons/yaml".source = "${templateDir}/yaml";
    # };

    extraConfigLua = ''
      require("esqueleto").setup({
        directories = { vim.fn.stdpath("config") .. "/skeletons" },
        patterns = { "python", "go", "rust", "yaml" },
        autouse = true,
      })
    '';
  };
}
