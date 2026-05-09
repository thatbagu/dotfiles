{ lib, config, ... }: {
  # Import all your configuration modules here
  imports = [
    ./bufferlines
    ./colorschemes
    ./completion
    ./dap
    ./filetrees
    ./git
    ./keys.nix
    ./languages
    ./lsp
    ./none-ls
    ./pluginmanagers
    ./sets
    ./skeletons
    ./snippets
    ./statusline
    ./telescope
    ./ui
    ./utils
  ];

  # Suppress deprecation warnings
  extraConfigLua = ''
    local original_notify = vim.notify
    vim.notify = function(msg, level, opts)
      if type(msg) == "string" and (
        msg:match("buf_get_clients.*deprecated") or
        msg:match("is_stopped.*deprecated") or
        msg:match("deprecated.*is_stopped")
      ) then
        return
      end
      original_notify(msg, level, opts)
    end
  '';

  bufferlines.enable = lib.mkDefault true;
  colorschemes.enable = lib.mkDefault true;
  completion.enable = lib.mkDefault true;
  dap.enable = lib.mkDefault true;
  filetrees.enable = lib.mkDefault true;
  git.enable = lib.mkDefault true;
  keys.enable = true;
  languages.enable = true;
  lsp.enable = lib.mkDefault true;
  none-ls.enable = lib.mkDefault false;
  sets.enable = lib.mkDefault true;
  pluginmanagers.enable = lib.mkDefault true;
  skeletons.enable = lib.mkDefault true;
  snippets.enable = lib.mkDefault true;
  statusline.enable = lib.mkDefault true;
  telescope.enable = lib.mkDefault true;
  ui.enable = lib.mkDefault true;
  utils.enable = lib.mkDefault true;
}
