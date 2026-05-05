{ lib, config, ... }: {
  options = {
    baleia.enable = lib.mkEnableOption "Enable terminal rendering for .dump files";
  };
  config = lib.mkIf config.baleia.enable {
    extraConfigLua = ''
      vim.api.nvim_create_autocmd("BufReadPost", {
        pattern = { "*.dump" },
        callback = function(args)
          local filepath = vim.api.nvim_buf_get_name(args.buf)
          local orig_buf = args.buf
          vim.cmd("enew")
          vim.fn.termopen("cat " .. vim.fn.shellescape(filepath), {
            on_exit = function()
              vim.schedule(function()
                vim.cmd("stopinsert")
              end)
            end,
          })
          vim.api.nvim_buf_delete(orig_buf, { force = true })
        end,
      })
    '';
  };
}
