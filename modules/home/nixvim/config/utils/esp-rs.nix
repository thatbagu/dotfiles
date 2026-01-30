{ lib, config, ... }: {
  options = {
    esp-rs.enable = lib.mkEnableOption "Enable esp-rs embedded development module";
  };

  config = lib.mkIf config.esp-rs.enable {
    # ESP-RS development keymaps and configuration
    keymaps = [
      # Build commands
      {
        mode = "n";
        key = "<leader>eb";
        action = "<cmd>!cargo build<cr>";
        options = {
          desc = "ESP: Build project";
          silent = false;
        };
      }
      {
        mode = "n";
        key = "<leader>er";
        action = "<cmd>!cargo build --release<cr>";
        options = {
          desc = "ESP: Build release";
          silent = false;
        };
      }
      # Flash commands
      {
        mode = "n";
        key = "<leader>ef";
        action = "<cmd>!cargo espflash flash --monitor<cr>";
        options = {
          desc = "ESP: Flash and monitor";
          silent = false;
        };
      }
      {
        mode = "n";
        key = "<leader>eF";
        action = "<cmd>!cargo espflash flash --release --monitor<cr>";
        options = {
          desc = "ESP: Flash release and monitor";
          silent = false;
        };
      }
      # Monitor
      {
        mode = "n";
        key = "<leader>em";
        action = "<cmd>!cargo espflash monitor<cr>";
        options = {
          desc = "ESP: Serial monitor";
          silent = false;
        };
      }
      # Check and test
      {
        mode = "n";
        key = "<leader>ec";
        action = "<cmd>!cargo check<cr>";
        options = {
          desc = "ESP: Check code";
          silent = false;
        };
      }
      {
        mode = "n";
        key = "<leader>et";
        action = "<cmd>!cargo test<cr>";
        options = {
          desc = "ESP: Run tests";
          silent = false;
        };
      }
      # Clean
      {
        mode = "n";
        key = "<leader>eC";
        action = "<cmd>!cargo clean<cr>";
        options = {
          desc = "ESP: Clean build artifacts";
          silent = false;
        };
      }
    ];

    # Additional Rust embedded configuration
    extraConfigLua = ''
      -- ESP-RS development helpers

      -- Auto-detect ESP32 projects and set rust-analyzer target
      vim.api.nvim_create_autocmd({"BufEnter", "BufWinEnter"}, {
        pattern = {"*.rs"},
        callback = function()
          -- Check if we're in an ESP project (has .cargo/config.toml with xtensa/riscv target)
          local cargo_config = vim.fn.findfile(".cargo/config.toml", ".;")
          if cargo_config ~= "" then
            -- Read the config to detect ESP target
            local config_content = vim.fn.readfile(cargo_config)
            for _, line in ipairs(config_content) do
              if string.match(line, "xtensa") or string.match(line, "riscv32") then
                -- Set LSP to understand embedded environment
                vim.b.rust_analyzer_settings = {
                  ["rust-analyzer"] = {
                    cargo = {
                      allFeatures = true,
                    },
                    checkOnSave = {
                      command = "clippy",
                      allTargets = false,
                    },
                  }
                }
                break
              end
            end
          end
        end,
      })

      -- Helper function to create new ESP project
      vim.api.nvim_create_user_command("EspNew", function(opts)
        local board = opts.args ~= "" and opts.args or "esp32"
        vim.cmd("!cargo generate esp-rs/esp-template --name " .. vim.fn.expand("%:p:h:t"))
      end, {
        nargs = "?",
        desc = "Create new ESP-RS project (optional: board name)",
      })

      -- Helper to install ESP toolchain
      vim.api.nvim_create_user_command("EspSetup", function()
        vim.cmd("!rustup default stable && rustup component add rust-analyzer && espup install")
      end, {
        desc = "Install ESP Rust toolchain with espup",
      })

      -- Helper to update ESP toolchain
      vim.api.nvim_create_user_command("EspUpdate", function()
        vim.cmd("!espup update")
      end, {
        desc = "Update ESP Rust toolchain",
      })
    '';
  };
}
