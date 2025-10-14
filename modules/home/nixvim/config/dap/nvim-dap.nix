{ lib, config, ... }: {
  options = {
    nvim-dap.enable = lib.mkEnableOption "Enable Debug Adapter Protocol module";
  };
  config = lib.mkIf config.nvim-dap.enable {
    plugins.dap = {
      enable = true;
      signs = {
        dapBreakpoint = {
          text = "●";
          texthl = "DapBreakpoint";
        };
        dapBreakpointCondition = {
          text = "●";
          texthl = "DapBreakpointCondition";
        };
        dapLogPoint = {
          text = "◆";
          texthl = "DapLogPoint";
        };
      };
      # Remove extensions here - they've been moved to top-level plugins
      configurations = {
        rust = [
          {
            name = "Launch file";
            type = "codelldb";
            request = "launch";
            program = "#{workspaceFolder}/target/debug/#{program}";
            args = [ ];
            cwd = "#{workspaceFolder}";
            stopOnEntry = false;
            sourceLanguages = [ "rust" ];
          }
          {
            name = "Attach to process";
            type = "codelldb";
            request = "attach";
            pid = "\${require('dap.utils').pick_process()}";
            args = [ ];
            sourceLanguages = [ "rust" ];
          }
        ];
        go = [
          {
            type = "go";
            name = "Debug Package";
            request = "launch";
            mode = "debug";
            program = "#{fileDirname}";
          }
          {
            type = "go";
            name = "Debug file";
            request = "launch";
            mode = "debug";
            program = "#{file}";
          }
          {
            type = "go";
            name = "Debug test";
            request = "launch";
            mode = "test";
            program = "#{fileDirname}";
          }
          {
            type = "go";
            name = "Attach to Process";
            request = "attach";
            mode = "local";
            processId = "\${require('dap.utils').pick_process()}";
          }
        ];
      };
    };

    # These plugins are now top-level, not extensions
    plugins.dap-python = { enable = true; };

    plugins.dap-ui = {
      enable = true;
      settings = { floating = { mappings = { close = [ "<ESC>" "q" ]; }; }; };
    };

    plugins.dap-virtual-text = { enable = true; };

    keymaps = [
      {
        mode = "n";
        key = "<leader>dB";
        action =
          "\n        <cmd>lua require('dap').set_breakpoint(vim.fn.input('Breakpoint condition: '))<cr>\n      ";
        options = {
          silent = true;
          desc = "Breakpoint Condition";
        };
      }
      {
        mode = "n";
        key = "<leader>db";
        action = ":DapToggleBreakpoint<cr>";
        options = {
          silent = true;
          desc = "Toggle Breakpoint";
        };
      }
      {
        mode = "n";
        key = "<leader>dc";
        action = ":DapContinue<cr>";
        options = {
          silent = true;
          desc = "Continue";
        };
      }
      {
        mode = "n";
        key = "<leader>da";
        action = "<cmd>lua require('dap').continue({ before = get_args })<cr>";
        options = {
          silent = true;
          desc = "Run with Args";
        };
      }
      {
        mode = "n";
        key = "<leader>dC";
        action = "<cmd>lua require('dap').run_to_cursor()<cr>";
        options = {
          silent = true;
          desc = "Run to cursor";
        };
      }
      {
        mode = "n";
        key = "<leader>dg";
        action = "<cmd>lua require('dap').goto_()<cr>";
        options = {
          silent = true;
          desc = "Go to line (no execute)";
        };
      }
      {
        mode = "n";
        key = "<leader>di";
        action = ":DapStepInto<cr>";
        options = {
          silent = true;
          desc = "Step into";
        };
      }
      {
        mode = "n";
        key = "<leader>dj";
        action = "\n        <cmd>lua require('dap').down()<cr>\n      ";
        options = {
          silent = true;
          desc = "Down";
        };
      }
      {
        mode = "n";
        key = "<leader>dk";
        action = "<cmd>lua require('dap').up()<cr>";
        options = {
          silent = true;
          desc = "Up";
        };
      }
      {
        mode = "n";
        key = "<leader>dl";
        action = "<cmd>lua require('dap').run_last()<cr>";
        options = {
          silent = true;
          desc = "Run Last";
        };
      }
      {
        mode = "n";
        key = "<leader>do";
        action = ":DapStepOut<cr>";
        options = {
          silent = true;
          desc = "Step Out";
        };
      }
      {
        mode = "n";
        key = "<leader>dO";
        action = ":DapStepOver<cr>";
        options = {
          silent = true;
          desc = "Step Over";
        };
      }
      {
        mode = "n";
        key = "<leader>dp";
        action = "<cmd>lua require('dap').pause()<cr>";
        options = {
          silent = true;
          desc = "Pause";
        };
      }
      {
        mode = "n";
        key = "<leader>dr";
        action = ":DapToggleRepl<cr>";
        options = {
          silent = true;
          desc = "Toggle REPL";
        };
      }
      {
        mode = "n";
        key = "<leader>ds";
        action = "<cmd>lua require('dap').session()<cr>";
        options = {
          silent = true;
          desc = "Session";
        };
      }
      {
        mode = "n";
        key = "<leader>dt";
        action = ":DapTerminate<cr>";
        options = {
          silent = true;
          desc = "Terminate";
        };
      }
      {
        mode = "n";
        key = "<leader>du";
        action = "<cmd>lua require('dapui').toggle()<cr>";
        options = {
          silent = true;
          desc = "Dap UI";
        };
      }
      {
        mode = "n";
        key = "<leader>dw";
        action = "<cmd>lua require('dap.ui.widgets').hover()<cr>";
        options = {
          silent = true;
          desc = "Widgets";
        };
      }
      {
        mode = [ "n" "v" ];
        key = "<leader>de";
        action = "<cmd>lua require('dapui').eval()<cr>";
        options = {
          silent = true;
          desc = "Eval";
        };
      }
    ];
  };
}
