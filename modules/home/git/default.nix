{ pkgs, lib, config, ... }:

with lib;
let cfg = config.modules.git;

in {
  options.modules.git = { enable = mkEnableOption "git"; };
  config = mkIf cfg.enable {
    programs.git = {
      enable = true;
      settings = {
        user.name = "thatbagu";
        init = { defaultBranch = "main"; };
        core = { excludesfile = "$NIXOS_CONFIG_DIR/scripts/gitignore"; };
        safe = { directory = "'*'"; };
        credential = {
          helper = ''
            !f() { echo "username=thatbagu
            password=$(cat $GITHUB_TOKEN_PATH)
            "; }; f'';
        };
      };
    };
  };
}
