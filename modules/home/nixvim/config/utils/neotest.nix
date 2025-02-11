{ lib, config, pkgs, ... }: {
  options = { neotest.enable = lib.mkEnableOption "Enable neotest module"; };
  config = lib.mkIf config.neotest.enable {
    plugins = {
      neotest = {
        enable = true;
        adapters = {
          python = {
            enable = true;
            settings = { dap = { justMyCode = false; }; };
          };
          rust = { enable = true; };
          go = { enable = true; };
          vitest = { enable = true; };
        };
        settings = {
          output = {
            enabled = true;
            open_on_run = true;
          };
          summary = { enabled = true; };
        };
      };
    };
    keymaps = [
      {
        mode = "n";
        key = "<leader>tt";
        action = "<cmd>lua require('neotest').run.run(vim.fn.expand '%')<CR>";
        options = {
          desc = "Run File";
          silent = true;
        };
      }
      {
        mode = "n";
        key = "<leader>tT";
        action = "<cmd>lua require('neotest').run.run(vim.loop.cwd())<CR>";
        options = {
          desc = "Run All Test Files";
          silent = true;
        };
      }
      {
        mode = "n";
        key = "<leader>tr";
        action = "<cmd>lua require('neotest').run.run()<CR>";
        options = {
          desc = "Run Nearest";
          silent = true;
        };
      }
      {
        mode = "n";
        key = "<leader>td";
        action = "<cmd>lua require('neotest').run.run({strategy = 'dap'})<CR>";
        options = {
          desc = "Run Nearest with debugger";
          silent = true;
        };
      }
      {
        mode = "n";
        key = "<leader>ts";
        action = "<cmd>lua require('neotest').summary.toggle()<CR>";
        options = {
          desc = "Toggle Summary";
          silent = true;
        };
      }
      {
        mode = "n";
        key = "<leader>to";
        action =
          "<cmd>lua require('neotest').output.open{ enter = true, auto_close = true }<CR>";
        options = {
          desc = "Show Output";
          silent = true;
        };
      }
      {
        mode = "n";
        key = "<leader>tO";
        action = "<cmd>lua require('neotest').output_panel.toggle()<CR>";
        options = {
          desc = "Toggle Output Panel";
          silent = true;
        };
      }
      {
        mode = "n";
        key = "<leader>tS";
        action = "<cmd>lua require('neotest').run.stop()<CR>";
        options = {
          desc = "Stop";
          silent = true;
        };
      }
    ];
  };
}
