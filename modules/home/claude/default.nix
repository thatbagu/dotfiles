{ pkgs, lib, config, claude-code, ... }:

with lib;
let
  cfg = config.modules.claude;

  # Hook to resume media when user submits a prompt (Claude starts thinking)
  claude-resume-media = pkgs.writeShellScriptBin "claude-resume-media" ''
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Resume hook called" >> /tmp/claude-hooks.log

    # Get current workspace
    CURRENT_WORKSPACE=$(hyprctl activeworkspace -j 2>/dev/null | jq -r '.id // empty')

    # Find Firefox media window address
    MEDIA_WINDOW=$(hyprctl clients -j 2>/dev/null | jq -r '.[] | select(.class == "firefox" and (.title | contains("YouTube") or contains("Twitch"))) | .address' | head -1)

    if [ -n "$CURRENT_WORKSPACE" ] && [ -n "$MEDIA_WINDOW" ]; then
      # Move Firefox media window back to current workspace
      hyprctl dispatch movetoworkspacesilent "$CURRENT_WORKSPACE",address:$MEDIA_WINDOW 2>/dev/null || true

      # Focus on the media window (brainrot time)
      hyprctl dispatch focuswindow address:$MEDIA_WINDOW 2>/dev/null || true
    fi

    # Resume media playback
    ${pkgs.playerctl}/bin/playerctl play 2>/dev/null || true

    exit 0
  '';

  # Hook to pause media when Claude finishes responding
  claude-pause-media = pkgs.writeShellScriptBin "claude-pause-media" ''
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Pause hook called" >> /tmp/claude-hooks.log

    # Get the current active window (terminal with Claude)
    ACTIVE_WINDOW=$(hyprctl activewindow -j 2>/dev/null | jq -r '.address // empty')

    # Pause media
    ${pkgs.playerctl}/bin/playerctl pause 2>/dev/null || true

    # Focus on terminal FIRST (before moving windows)
    if [ -n "$ACTIVE_WINDOW" ]; then
      hyprctl dispatch focuswindow address:$ACTIVE_WINDOW 2>/dev/null || true
    fi

    # Then move Firefox media windows to workspace 10 (focus stays on terminal)
    hyprctl clients -j 2>/dev/null | jq -r '.[] | select(.class == "firefox" and (.title | contains("YouTube") or contains("Twitch"))) | .address' | while read -r addr; do
      hyprctl dispatch movetoworkspacesilent 10,address:$addr 2>/dev/null || true
    done

    exit 0
  '';

  # Claude Code settings with hooks configured
  claudeSettings = if cfg.enableBrainrot then {
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
      PreToolUse = [{
        matcher = "AskUserQuestion";
        hooks = [{
          type = "command";
          command = "claude-pause-media";
        }];
      }];
      PostToolUse = [{
        matcher = "AskUserQuestion";
        hooks = [{
          type = "command";
          command = "claude-resume-media";
        }];
      }];
    };
  } else {
    hooks = { };
  };

in {
  options.modules.claude = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable Claude Code module";
    };

    enableBrainrot = mkOption {
      type = types.bool;
      default = false;
      description =
        "Enable Claude Code media pause/resume hooks (brainrot mode)";
    };
  };

  config = mkIf cfg.enable {
    # Add claude-code and hook scripts to PATH
    home.packages = [ claude-code ] ++ (if cfg.enableBrainrot then [
      claude-resume-media
      claude-pause-media
      pkgs.playerctl
    ] else
      [ ]);

    # Configure Claude Code settings in ~/.claude/settings.json
    home.file.".claude/settings.json" = {
      text = builtins.toJSON claudeSettings;
    };
  };
}
