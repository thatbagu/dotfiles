{ lib, config, ... }: {
  options = {
    none-ls-nvim.enable = lib.mkEnableOption "Enable none-ls-nvim module";
  };
  config = lib.mkIf config.none-ls-nvim.enable {
    plugins.none-ls = {
      enable = true;
      settings = {
        enableLspFormat = false;
        updateInInsert = false;
        onAttach = ''
          function(client, bufnr)
              if client.supports_method "textDocument/formatting" then
                vim.api.nvim_clear_autocmds { group = augroup, buffer = bufnr }
                vim.api.nvim_create_autocmd("BufWritePre", {
                  group = augroup,
                  buffer = bufnr,
                  callback = function()
                    vim.lsp.buf.format { bufnr = bufnr }
                  end,
                })
              end
            end
        '';
      };
      sources = {
        code_actions = {
          gitsigns.enable = true;
          statix.enable = true;
        };
        diagnostics = {
          statix = { enable = true; };
          mypy = { enable = true; };
          golangci_lint = { enable = true; };
          terraform_validate = { enable = true; };
        };
      };
    };
  };
}
