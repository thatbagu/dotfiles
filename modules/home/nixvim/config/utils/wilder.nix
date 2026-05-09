{ lib, config, ... }:
{
  options = {
    wilder.enable = lib.mkEnableOption "Enable wilder module";
  };
  config = lib.mkIf config.wilder.enable {
    plugins.wilder = {
      enable = true;
      settings.modes = [
        ":"
        "/"
        "?"
      ];
      options.pipeline = [
        {
          __raw = ''
            wilder.branch(
              wilder.cmdline_pipeline({
                fuzzy = 1,
                use_python = 0,
              }),
              {
                wilder.check(function(ctx, x) return x == "" end),
                wilder.history(),
              },
              wilder.vim_search_pipeline()
            )
          '';
        }
      ];
    };
  };
}
