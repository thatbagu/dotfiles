{ lib, config, pkgs, ... }: {
  options = { typr.enable = lib.mkEnableOption "Enable typr module"; };

  config = lib.mkIf config.typr.enable {
    extraPlugins = with pkgs.vimUtils; [
      (buildVimPlugin {
        pname = "volt";
        version = "2024-02-07";
        src = pkgs.fetchFromGitHub {
          owner = "nvzone";
          repo = "volt";
          rev = "main";
          sha256 = "sha256-uhNPJfqq28iAGSBEDobQgNuLNThwkMqpXgRO27eTtVI=";
        };
      })
      (buildVimPlugin {
        pname = "typr";
        version = "2024-02-07";
        src = pkgs.fetchFromGitHub {
          owner = "nvzone";
          repo = "typr";
          rev = "main";
          sha256 = "sha256-CHZ83Ctkv7mVOzVL4iSS3SgVOxTdMwecjCaomwPpsK4=";
        };
      })
    ];

    extraConfigLua = ''
      require("typr").setup({})
    '';
  };
}

