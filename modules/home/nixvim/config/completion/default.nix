{ lib, config, ... }: {
  imports = [ ./cmp.nix ./codecompanion.nix ];

  options = {
    completion.enable = lib.mkEnableOption "Enable completion module";
  };
  config = lib.mkIf config.completion.enable {
    cmp.enable = lib.mkDefault true;
    codecompanion = {
      enable = lib.mkDefault true;
      chatPosition = "vertical";
      chatWidth = 0.45;
      defaultAdapter = "anthropic";
    };
  };
}
