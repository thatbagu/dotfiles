{ pkgs, lib, config, ... }:
with lib;
let cfg = config.modules.waybar;
in {
    options.modules.waybar = { enable = mkEnableOption "waybar"; };
    config = mkIf cfg.enable {
        programs.waybar = {
        enable = true;
        settings = {
          mainBar = {
            layer = "top";
            position = "top";
            height = 28;
            modules-left = ["hyprland/workspaces" "hyprland/language"];
            modules-center = ["clock"];
            modules-right = ["network" "backlight" "wireplumber" "battery"];
        "hyprland/language" = {
            format-en = "US";
            format-ru = "RU";
            min-length = 5;
            tooltip = false;
        };
        "hyprland/workspaces" = {
            "on-click" = "activate";
            "format" = "{icon}";
            "format-icons" = {
                "default" = "";
                "1" = "1";
                "2" = "2";
                "3" = "3";
                "4" = "4";
                "5" = "5";
                "6" = "6";
                "7" = "7";
                "8" = "8";
                "9" = "9";
            };
            "persistent_workspaces" = {
                "1" = [];
                "2" = [];
                "3" = [];
                "4" = [];
                "5" = [];
            };
        };
        "clock" = {
            "tooltip-format" = "{calendar}";
            "format" = "{:%I:%M %p | %a, %d %b %Y}";
        };
        "network" = {
            "format-wifi" = "{icon}  {essid}";
            "format-icons" = ["󰤯" "󰤟" "󰤢" "󰤥" "󰤨"];
            "format-ethernet" = "󰀂 {ifname}";
            "format-disconnected" = "󰖪 Disconnected";
            "tooltip-format-wifi" = "{icon} {essid}\n⇣{bandwidthDownBytes}  ⇡{bandwidthUpBytes}";
            "tooltip-format-ethernet" = "󰀂  {ifname}\n⇣{bandwidthDownBytes}  ⇡{bandwidthUpBytes}";
            "tooltip-format-disconnected" = "Disconnected";
            "interval" = 5;
            "nospacing" = 1;
        };
        "backlight" = {
            "format" = "{icon}";
            "format-icons" = ["󰃚" "󰃛" "󰃜" "󰃝" "󰃞" "󰃟" "󰃠"];
            "tooltip-format" = "Brightness: {percent}%";
            "on-scroll-up" = "brightnessctl set +5%";
            "on-scroll-down" = "brightnessctl set 5%-";
            "min-length" = 1;
        };
        "wireplumber" = {
            "format" = "{icon}  {volume}%";
            "format-bluetooth" = "󰂰 {volume}%";
            "format-muted" = "󰝟";
            "format-icons" = {
                "headphone" = "󰋋";
                "hands-free" = "󰂑";
                "headset" = "󰋎";
                "phone" = "󰏲";
                "portable" = "󰦢";
                "car" = "󰄋";
                "default" = ["󰕿" "󰖀" "󰕾"];
            };

            "scroll-step" = 1;
            "on-click" = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
            "on-scroll-up" = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 1%+";
            "on-scroll-down" = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 1%-";
            "tooltip" = true;
            "tooltip-format" = "{icon} {volume}%";
        };
        "battery" = {
            "format" = "{capacity}% {icon}";
            "format-icons" = {
                "charging" = [
                    "󰢜" 
                    "󰂆" 
                    "󰂇" 
                    "󰂈" 
                    "󰢝" 
                    "󰂉" 
                    "󰢞" 
                    "󰂊" 
                    "󰂋" 
                    "󰂅" 
                ];
                "default" = [
                    "󰁺" 
                    "󰁻" 
                    "󰁼" 
                    "󰁽" 
                    "󰁾" 
                    "󰁿" 
                    "󰂀" 
                    "󰂁" 
                    "󰂂" 
                    "󰁹" 
                ];
            };
            "format-full" = "Charged ";
            "interval" = 5;
            "states" = {
                "warning" = 20;
                "critical" = 10;
            };
            "tooltip" = false;
          };
      };
    };

    style = builtins.readFile ./style.css;
  };
};
}
