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
      lsp = {
        message = {
          enabled = true;
        };
        progress = {
          enabled = false;
          view = "mini";
        };
        override = {
          "vim.lsp.util.convert_input_to_markdown_lines" = true;
          "vim.lsp.util.stylize_markdown" = true;
          "cmp.entry.get_documentation" = true;
        };
        hover = {
          enabled = false;
        };
        signature = {
          enabled = false;
        };
      };
      popupmenu = {
        enabled = true;
        backend = "nui";
      };
    };
  };
}
