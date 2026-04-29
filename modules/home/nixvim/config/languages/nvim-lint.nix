{ lib, config, ... }:
{
  options = {
    nvim-lint.enable = lib.mkEnableOption "Enable nvim-lint module";
  };
  config = lib.mkIf config.nvim-lint.enable {
    plugins.lint = {
      enable = true;
      lintersByFt = {
        c = [ "cpplint" ];
        cpp = [ "cpplint" ];
        go = [ "golangci-lint" ];
        nix = [ "statix" ];
        lua = [ "selene" ];
        python = [ "flake8" "ruff" ];
        rust = [ "clippy" ];
        terraform = [ "tflint" ];
        javascript = [ "eslint_d" ];
        javascriptreact = [ "eslint_d" ];
        typescript = [ "eslint_d" ];
        typescriptreact = [ "eslint_d" ];
        json = [ "jsonlint" ];
        bash = [ "shellcheck" ];
        sql = [ "sqlfluff" ];
      };
    };

    extraConfigLua = ''
      require('lint').linters.sqlfluff.args = {
        'lint', '--format', 'json', '--dialect', 'ansi', '--exclude-rules', 'CP01,CP02,CP03,CP04,CP05,AM04,LT09'
      }

      vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost", "InsertLeave" }, {
        callback = function()
          require("lint").try_lint()
        end,
      })
    '';
  };
}
