final: prev: {
  vimPlugins = prev.vimPlugins // {
    nvim-lspconfig = prev.vimPlugins.nvim-lspconfig.overrideAttrs (old: {
      postPatch = (old.postPatch or "") + ''
        substituteInPlace plugin/lspconfig.lua \
          --replace-warn 'client.is_stopped()' 'client:is_stopped()'
      '';
    });
  };
}
