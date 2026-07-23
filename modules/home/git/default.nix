{ pkgs, lib, config, ... }:

with lib;
let cfg = config.modules.git;

in {
  options.modules.git = {
    enable = mkEnableOption "git";
    gpgSigningKey = mkOption {
      type = types.str;
      default = "";
      description = "GPG key fingerprint for commit signing";
    };
  };
  config = mkIf cfg.enable {
    programs.gpg = {
      enable = true;
    };

    services.gpg-agent = {
      enable = true;
      pinentry.package = pkgs.pinentry-curses;
      defaultCacheTtl = 86400;
      maxCacheTtl = 86400;
    };

    programs.git = {
      enable = true;
      settings = {
        user.name = "thatbagu";
        init = { defaultBranch = "main"; };
        core = { excludesfile = "$NIXOS_CONFIG_DIR/scripts/gitignore"; };
        safe = { directory = "'*'"; };
        commit.gpgsign = mkIf (cfg.gpgSigningKey != "") true;
        user.signingKey = mkIf (cfg.gpgSigningKey != "") cfg.gpgSigningKey;
        credential = {
          helper = ''
            !f() { echo "username=thatbagu
            password=$(cat $GITHUB_TOKEN_PATH)
            "; }; f'';
        };
      };
    };

    # Import GPG private key from SOPS secret on activation
    home.activation.importGpgKey = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if [ -f /run/secrets/gpg_private_key ]; then
        $DRY_RUN_CMD ${pkgs.gnupg}/bin/gpg --batch --import /run/secrets/gpg_private_key 2>/dev/null || true
      fi
    '';
  };
}
