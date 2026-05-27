{ lib, config, ... }: {
  options = {
    nvim-ufo.enable = lib.mkEnableOption "Enable nvim-ufo folding";
  };
  config = lib.mkIf config.nvim-ufo.enable {
    plugins.nvim-ufo = {
      enable = true;
      settings = {
        provider_selector.__raw = ''
          function(bufnr, filetype, buftype)
            local function handleFallback(bufnr2, err, providerName)
              if type(err) == 'string' and err:match('UfoFallbackException') then
                return require('ufo').getFolds(bufnr2, providerName)
              else
                return require('promise').reject(err)
              end
            end
            return function(bufnr2)
              return require('ufo').getFolds(bufnr2, 'lsp')
                :catch(function(err) return handleFallback(bufnr2, err, 'treesitter') end)
                :catch(function(err) return handleFallback(bufnr2, err, 'indent') end)
            end
          end
        '';
        fold_virt_text_handler.__raw = ''
          function(virtText, lnum, endLnum, width, truncate)
            local newVirtText = {}
            local suffix = (' 󰁂 %d '):format(endLnum - lnum)
            local sufWidth = vim.fn.strdisplaywidth(suffix)
            local targetWidth = width - sufWidth
            local curWidth = 0
            for _, chunk in ipairs(virtText) do
              local chunkText = chunk[1]
              local chunkWidth = vim.fn.strdisplaywidth(chunkText)
              if targetWidth > curWidth + chunkWidth then
                table.insert(newVirtText, chunk)
              else
                chunkText = truncate(chunkText, targetWidth - curWidth)
                local hlGroup = chunk[2]
                table.insert(newVirtText, {chunkText, hlGroup})
                chunkWidth = vim.fn.strdisplaywidth(chunkText)
                if curWidth + chunkWidth < targetWidth then
                  suffix = suffix .. (' '):rep(targetWidth - curWidth - chunkWidth)
                end
                break
              end
              curWidth = curWidth + chunkWidth
            end
            table.insert(newVirtText, {suffix, 'MoreMsg'})
            return newVirtText
          end
        '';
      };
    };

    keymaps = [
      {
        mode = "n";
        key = "zR";
        action.__raw = "require('ufo').openAllFolds";
        options.desc = "Open all folds";
      }
      {
        mode = "n";
        key = "zM";
        action.__raw = "require('ufo').closeAllFolds";
        options.desc = "Close all folds";
      }
      {
        mode = "n";
        key = "zr";
        action.__raw = "require('ufo').openFoldsExceptKinds";
        options.desc = "Open folds (except kinds)";
      }
      {
        mode = "n";
        key = "zm";
        action.__raw = "require('ufo').closeFoldsWith";
        options.desc = "Close folds with";
      }
    ];
  };
}
