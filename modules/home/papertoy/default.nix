{ inputs, pkgs, lib, config, ... }:
with lib;
let
  cfg = config.modules.papertoy;
  papertoy = inputs.papertoy.packages.${pkgs.system}.default;
in {
  options.modules.papertoy = {
    enable = mkEnableOption "papertoy animated wallpapers";

    shader = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Path to the shader file to use as wallpaper";
      example = literalExpression "../../../pics/shapes.glsl";
    };

    output = mkOption {
      type = types.int;
      default = 0;
      description = "Output index to render to";
    };

    autostart = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to automatically start papertoy with Hyprland";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ papertoy ];

    # Add to Hyprland autostart if both are enabled and shader is specified
    wayland.windowManager.hyprland = mkIf
      (config.modules.hyprland.enable && cfg.autostart && cfg.shader != null) {
        extraConfig = ''
          # Start papertoy animated wallpaper
          exec-once = ${papertoy}/bin/papertoy --output ${
            toString cfg.output
          } ${cfg.shader}
        '';
      };

    # Create a script for easy shader switching
    home.file.".local/bin/papertoy-switch" = mkIf (cfg.shader != null) {
      text = ''
        #!/usr/bin/env bash
        # Kill existing papertoy instance
        pkill papertoy

        # Start new instance with selected shader
        SHADER_FILE="''${1:-${cfg.shader}}"
        OUTPUT="''${2:-${toString cfg.output}}"

        if [[ -f "$SHADER_FILE" ]]; then
          ${papertoy}/bin/papertoy --output "$OUTPUT" "$SHADER_FILE" &
          echo "Started papertoy with shader: $SHADER_FILE"
        else
          echo "Shader file not found: $SHADER_FILE"
          exit 1
        fi
      '';
      executable = true;
    };
  };
}
