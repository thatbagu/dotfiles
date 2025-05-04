{ pkgs, lib, config, ... }:
with lib;
let cfg = config.modules.k9s;
in {
  options.modules.k9s = { enable = mkEnableOption "k9s"; };
  config = mkIf cfg.enable {
    programs.k9s = {
      enable = true;
      settings = {
        k9s = {
          refreshRate = 2;
          maxConnRetry = 5;
          readOnly = false;
          ui = {
            skin = "transparent";
            enableMouse = false;
            headless = false;
            logoless = false;
            crumbsless = false;
            noIcons = false;
          };
        };
      };
    };

    # Add the transparent skin configuration
    xdg.configFile."k9s/skins/transparent.yaml".text = ''
      # -----------------------------------------------------------------------------
      # Transparent skin
      # Preserve your terminal session background color
      # -----------------------------------------------------------------------------

      # Skin...
      k9s:
        body:
          bgColor: default
        prompt:
          bgColor: default
        info:
          sectionColor: default
        dialog:
          bgColor: default
          labelFgColor: default
          fieldFgColor: default
        frame:
          crumbs:
            bgColor: default
          title:
            bgColor: default
            counterColor: default
          menu:
            fgColor: default
        views:
          charts:
            bgColor: default
          table:
            bgColor: default
            header:
              fgColor: default
              bgColor: default
          xray:
            bgColor: default
          logs:
            bgColor: default
            indicator:
              bgColor: default
              toggleOnColor: default
              toggleOffColor: default
          yaml:
            colonColor: default
            valueColor: default
    '';
  };
}
