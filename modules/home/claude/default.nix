{ pkgs, lib, config, claude-code, ... }:

with lib;
let
  cfg = config.modules.claude;

  # Hook to resume media when user submits a prompt (Claude starts thinking)
  claude-resume-media = pkgs.writeShellScriptBin "claude-resume-media" ''
    ${pkgs.playerctl}/bin/playerctl play 2>/dev/null || true
    exit 0
  '';

  # Hook to pause media when Claude finishes responding
  claude-pause-media = pkgs.writeShellScriptBin "claude-pause-media" ''
    ${pkgs.playerctl}/bin/playerctl pause 2>/dev/null || true
    exit 0
  '';

  # Claude Code settings with hooks configured
  claudeSettings = {
    hooks = {
      UserPromptSubmit = [{
        hooks = [{
          type = "command";
          command = "claude-resume-media";
        }];
      }];
      Stop = [{
        hooks = [{
          type = "command";
          command = "claude-pause-media";
        }];
      }];
    };
  };

in {
  options.modules.claude = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable Claude Code media pause hooks";
    };
  };

  config = mkIf cfg.enable {
    # Add claude-code and hook scripts to PATH
    home.packages = [
      claude-code
      claude-resume-media
      claude-pause-media
      pkgs.playerctl
    ];

    # Configure Claude Code settings
    xdg.configFile."claude-code/settings.json" = {
      text = builtins.toJSON claudeSettings;
    };
  };
}
