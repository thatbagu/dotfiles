{ lib, config, ... }:
{
  options = {
    noice.enable = lib.mkEnableOption "Enable noice module";
  };
  config = lib.mkIf config.noice.enable {
    plugins.noice = {
      enable = true;
      notify = {
        enabled = false;
      };
      messages = {
        enabled = true; # Adds a padding-bottom to neovim statusline when set to false for some reason
      };

      popupmenu = {
        enabled = true;
        backend = "nui";
      };
    };
  };
}
