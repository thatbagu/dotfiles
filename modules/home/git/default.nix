{ pkgs, lib, config, ... }:

with lib;
let cfg = config.modules.git;

in {
  options.modules.git = { enable = mkEnableOption "git"; };
  config = mkIf cfg.enable {
    programs.git = {
      enable = true;
      userName = "Jahysama";
      userEmail = "megametagross@outlook.de";
      extraConfig = {
        init = { defaultBranch = "main"; };
        core = { excludesfile = "$NIXOS_CONFIG_DIR/scripts/gitignore"; };
        safe = { directory = "*"; };
        credential = {
          # Use the helper that reads the token directly
          helper = ''
            !f() { echo "username=Jahysama
            password=$(cat $GITHUB_TOKEN_PATH)"; }; f'';
        };
      };
    };
  };
}
