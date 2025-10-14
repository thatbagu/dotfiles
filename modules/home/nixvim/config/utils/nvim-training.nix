{ lib, config, pkgs, ... }: {
  options = {
    nvim-training.enable = lib.mkEnableOption "Enable nvim-training module";
  };

  config = lib.mkIf config.nvim-training.enable {
    extraPlugins = with pkgs.vimUtils;
      [
        (buildVimPlugin {
          pname = "nvim-training";
          version = "2025-02-14";
          src = pkgs.fetchFromGitHub {
            owner = "Weyaaron";
            repo = "nvim-training";
            rev = "main"; # or use a specific commit hash
            sha256 = ""; # Leave empty initially to get the correct hash
          };
        })
      ];

    extraConfigLua = ''
      require("nvim-training").configure({
        audio_feedback = false, -- Set to true if you have 'sox' installed
        counter_bounds = { 1, 5 },
        custom_collections = {},
        disabled_tags = { "treesitter" },
        disabled_collections = { "Treesitter-Tasks" },
        enable_counters = true,
        enable_events = true,
        enable_registers = false,
        enable_repeat_on_failure = false,
        enable_highlights = true,
        event_storage_directory_path = vim.fn.stdpath("data") .. "/nvim-training/",
        logging_args = {
          enable_logging = true,
          log_directory_path = vim.fn.stdpath("log") .. "/nvim-training/",
          log_file_path = os.date("%Y-%m-%d") .. ".log",
          display_logs = false,
          display_warnings = true,
        },
        possible_marks_list = { "a", "b", "c", "r", "s", "t", "d", "n", "e" },
        possible_register_list = { "a", "b", "c", "r", "s", "t", "d", "n", "e" },
        scheduler_args = { repetitions = 5 },
        task_alphabet = "ABCDEFGabddefg,",
      })
    '';

    keymaps = [
      {
        mode = "n";
        key = "<leader>Ts";
        action = "<cmd>Training Start<CR>";
        options = {
          silent = true;
          desc = "Start training session";
        };
      }
      {
        mode = "n";
        key = "<leader>Tt";
        action = "<cmd>Training Stop<CR>";
        options = {
          silent = true;
          desc = "Stop training session";
        };
      }
      {
        mode = "n";
        key = "<leader>Ta";
        action = "<cmd>Training Analyze<CR>";
        options = {
          silent = true;
          desc = "Analyze training progress";
        };
      }
    ];
  };
}
