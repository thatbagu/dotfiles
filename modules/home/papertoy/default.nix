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
      default = ../../../pics/shapes.glsl;
      description = "Path to the shader file to use as wallpaper";
      example = literalExpression "./shaders/seascape.glsl";
    };

    output = mkOption {
      type = types.int;
      default = 0;
      description = "Output index to render to";
    };

    startupDelay = mkOption {
      type = types.int;
      default = 5;
      description = "Delay in seconds before starting papertoy after Hyprland";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ papertoy ];

    # Create systemd user service for papertoy
    systemd.user.services.papertoy = mkIf (cfg.shader != null) {
      Unit = {
        Description = "Papertoy animated wallpaper";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
        Requisite = [ "graphical-session.target" ];
      };

      Service = {
        Type = "oneshot";
        ExecStartPre =
          "${pkgs.coreutils}/bin/sleep ${toString cfg.startupDelay}";
        ExecStart = "${papertoy}/bin/papertoy --output ${
            toString cfg.output
          } ${cfg.shader}";
        RemainAfterExit = true;
        Environment = [ "WAYLAND_DISPLAY=wayland-1" ];
      };

      Install = { WantedBy = [ "graphical-session.target" ]; };
    };
  };
}
