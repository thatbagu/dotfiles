{ inputs, pkgs, lib, config, ... }:
with lib;
let
  cfg = config.modules.papertoy;
  papertoy = inputs.papertoy.packages.${pkgs.stdenv.hostPlatform.system}.default;
in {
  options.modules.papertoy = {
    enable = mkEnableOption "papertoy animated wallpapers";
    shader = mkOption {
      type = types.nullOr types.path;
      default = ../../../pics/shapes.glsl;
      description = "Path to the shader file to use as wallpaper";
      example = literalExpression "./shaders/seascape.glsl";
    };
    output = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Output name to render to (e.g. HDMI-A-1). Default: first available output.";
    };

    startupDelay = mkOption {
      type = types.int;
      default = 5;
      description = "Delay in seconds before starting papertoy after Hyprland";
    };
  };
  config = mkIf cfg.enable {
    home.packages = [ papertoy ];
    wayland.windowManager.hyprland.settings.exec-once =
      mkIf (cfg.shader != null) (lib.mkAfter [
        "sleep ${toString cfg.startupDelay} && ${papertoy}/bin/papertoy${
          lib.optionalString (cfg.output != null) " --output ${cfg.output}"
        } ${cfg.shader}"
      ]);
  };
}
