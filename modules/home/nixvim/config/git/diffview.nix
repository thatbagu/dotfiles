{ lib, config, ... }:
{
  options = {
    diffview.enable = lib.mkEnableOption "Enable diffview module";
  };
  config = lib.mkIf config.diffview.enable {

    plugins.diffview = {
      enable = true;
    };

    # The current branch's PR base (via gh), fetched fresh, so the diff matches GitHub's.
    extraConfigLua = ''
      function _G.pr_base()
        local base = vim.fn.system("gh pr view --json baseRefName --jq .baseRefName 2>/dev/null"):gsub("%s+$", "")
        if vim.v.shell_error ~= 0 or base == "" then
          vim.notify("No PR for this branch (or gh is on the wrong account)", vim.log.levels.ERROR)
          return
        end
        vim.fn.system({ "git", "fetch", "--quiet", "origin", base })
        return "origin/" .. base
      end
    '';

    keymaps = [
      {
        mode = "n";
        key = "<leader>gd";
        action.__raw = ''
          function()
            local base = pr_base()
            if not base then return end
            vim.cmd("enew")
            vim.fn.setline(1, vim.fn.systemlist({ "git", "diff", base .. "...HEAD" }))
            vim.bo.buftype = "nofile"
            vim.bo.bufhidden = "wipe"
            vim.bo.modifiable = false
            vim.bo.filetype = "diff"
          end
        '';
        options = { desc = "PR diff (unified)"; };
      }
      {
        mode = "n";
        key = "<leader>gD";
        action.__raw = ''
          function()
            local base = pr_base()
            if base then vim.cmd("DiffviewOpen " .. base .. "...HEAD") end
          end
        '';
        options = { desc = "PR diff (diffview)"; };
      }
    ];
  };
}
