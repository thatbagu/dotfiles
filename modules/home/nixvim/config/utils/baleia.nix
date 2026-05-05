{ lib, config, ... }: {
  options = {
    baleia.enable = lib.mkEnableOption "Enable log highlighting for .dump files";
  };
  config = lib.mkIf config.baleia.enable {
    extraConfigLua = ''
      vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
        pattern = { "*.dump" },
        callback = function()
          vim.cmd([[
            syntax match DumpError   /\c\<\(error\|fail\|failed\|fatal\|critical\)\>/
            syntax match DumpWarn    /\c\<\(warn\|warning\)\>/
            syntax match DumpOk      /\c\<\(ok\|success\|done\|passed\)\>/
            syntax match DumpNumber  /\b[0-9]\+\(\.[0-9]\+\)\?\b/
            syntax match DumpPath    /\~\?\/[a-zA-Z0-9_.\/\-]*/
            syntax match DumpString  /"\([^"]*\)"/
            highlight DumpError  guifg=#ff5555 ctermfg=Red
            highlight DumpWarn   guifg=#ffb86c ctermfg=Yellow
            highlight DumpOk     guifg=#50fa7b ctermfg=Green
            highlight DumpNumber guifg=#bd93f9 ctermfg=Magenta
            highlight DumpPath   guifg=#6272a4 ctermfg=Blue
            highlight DumpString guifg=#f1fa8c ctermfg=Yellow
          ]])
        end,
      })
    '';
  };
}
