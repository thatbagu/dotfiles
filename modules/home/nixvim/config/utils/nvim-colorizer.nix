{ lib, config, ... }: {
  options = {
    nvim-colorizer.enable = lib.mkEnableOption "Enable nvim-colorizer module";
  };
  config = lib.mkIf config.nvim-colorizer.enable {
    # Changed from nvim-colorizer to colorizer
    plugins.colorizer = { enable = true; };
  };
}
