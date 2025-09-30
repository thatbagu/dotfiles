# Thanks for the keybinds primeagen and folke!
{ lib, config, ... }: {
  options = { keys.enable = lib.mkEnableOption "Enable keys module"; };
  config = lib.mkIf config.keys.enable {
    globals.mapleader = " ";
    keymaps = [
      {
        mode = "n";
        key = "<leader>l";
        action = "<cmd>lua require('lint').try_lint()<CR>";
        options = {
          silent = true;
          desc = "Trigger linting for current file";
        };
      }
      {
        mode = "n";
        key = "<leader>e";
        action = ":Neotree toggle reveal_force_cwd<cr>";
        options = {
          silent = true;
          desc = "Explorer NeoTree (root dir)";
        };
      }
      {
        mode = "n";
        key = "<leader>E";
        action = "<cmd>Neotree toggle<CR>";
        options = {
          silent = true;
          desc = "Explorer NeoTree (cwd)";
        };
      }
      {
        mode = "n";
        key = "<leader>be";
        action = ":Neotree buffers<CR>";
        options = {
          silent = true;
          desc = "Buffer explorer";
        };
      }
      {
        mode = "n";
        key = "<leader>ge";
        action = ":Neotree git_status<CR>";
        options = {
          silent = true;
          desc = "Git explorer";
        };
      }
      # Tabs
      {
        mode = "n";
        key = "<leader><tab>l";
        action = "<cmd>tablast<cr>";
        options = {
          silent = true;
          desc = "Last tab";
        };
      }

      {
        mode = "n";
        key = "<leader><tab>f";
        action = "<cmd>tabfirst<cr>";
        options = {
          silent = true;
          desc = "First Tab";
        };
      }

      {
        mode = "n";
        key = "<leader><tab><tab>";
        action = "<cmd>tabnew<cr>";
        options = {
          silent = true;
          desc = "New Tab";
        };
      }

      {
        mode = "n";
        key = "<leader><tab>]";
        action = "<cmd>tabnext<cr>";
        options = {
          silent = true;
          desc = "Next Tab";
        };
      }

      {
        mode = "n";
        key = "<leader><tab>d";
        action = "<cmd>tabclose<cr>";
        options = {
          silent = true;
          desc = "Close tab";
        };
      }

      {
        mode = "n";
        key = "<leader><tab>[";
        action = "<cmd>tabprevious<cr>";
        options = {
          silent = true;
          desc = "Previous Tab";
        };
      }

      {
        mode = "n";
        key = "<leader>ww";
        action = "<C-W>p";
        options = {
          silent = true;
          desc = "Other window";
        };
      }

      {
        mode = "n";
        key = "<leader>wd";
        action = "<C-W>c";
        options = {
          silent = true;
          desc = "Delete window";
        };
      }

      {
        mode = "n";
        key = "<leader>w-";
        action = "<C-W>s";
        options = {
          silent = true;
          desc = "Split window below";
        };
      }

      {
        mode = "n";
        key = "<leader>w|";
        action = "<C-W>v";
        options = {
          silent = true;
          desc = "Split window right";
        };
      }

      # Window navigation - Use leader key instead of Alt
      {
        mode = "n";
        key = "<leader>wh";
        action = "<C-w>h";
        options = { desc = "Go to left window"; };
      }
      {
        mode = "n";
        key = "<leader>wj";
        action = "<C-w>j";
        options = { desc = "Go to lower window"; };
      }
      {
        mode = "n";
        key = "<leader>wk";
        action = "<C-w>k";
        options = { desc = "Go to upper window"; };
      }
      {
        mode = "n";
        key = "<leader>wl";
        action = "<C-w>l";
        options = { desc = "Go to right window"; };
      }

      {
        mode = "n";
        key = "<C-s>";
        action = "<cmd>w<cr><esc>";
        options = {
          silent = true;
          desc = "Save file";
        };
      }

      # Quit/Session
      {
        mode = "n";
        key = "<leader>qq";
        action = "<cmd>quitall<cr><esc>";
        options = {
          silent = true;
          desc = "Quit all";
        };
      }

      {
        mode = "n";
        key = "<leader>qs";
        action = ":lua require('persistence').load()<cr>";
        options = {
          silent = true;
          desc = "Restore session";
        };
      }

      {
        mode = "n";
        key = "<leader>ql";
        action = "<cmd>lua require('persistence').load({ last = true })<cr>";
        options = {
          silent = true;
          desc = "Restore last session";
        };
      }

      {
        mode = "n";
        key = "<leader>qd";
        action = "<cmd>lua require('persistence').stop()<cr>";
        options = {
          silent = true;
          desc = "Don't save current session";
        };
      }

      # Toggle
      {
        mode = "n";
        key = "<leader>ul";
        action = ":lua ToggleLineNumber()<cr>";
        options = {
          silent = true;
          desc = "Toggle Line Numbers";
        };
      }

      {
        mode = "n";
        key = "<leader>uL";
        action = ":lua ToggleRelativeLineNumber()<cr>";
        options = {
          silent = true;
          desc = "Toggle Relative Line Numbers";
        };
      }

      {
        mode = "n";
        key = "<leader>uw";
        action = ":lua ToggleWrap()<cr>";
        options = {
          silent = true;
          desc = "Toggle Line Wrap";
        };
      }

      # Inlay Hints
      {
        mode = "n";
        key = "<leader>uh";
        action = ":lua ToggleInlayHints()<cr>";
        options = {
          silent = true;
          desc = "Toggle Inlay Hints";
        };
      }

      {
        mode = "v";
        key = "J";
        action = ":m '>+1<CR>gv=gv";
        options = {
          silent = true;
          desc = "Move up when line is highlighted";
        };
      }

      {
        mode = "v";
        key = "K";
        action = ":m '<-2<CR>gv=gv";
        options = {
          silent = true;
          desc = "Move down when line is highlighted";
        };
      }

      {
        mode = "n";
        key = "J";
        action = "mzJ`z";
        options = {
          silent = true;
          desc =
            "Allow cursor to stay in the same place after appeding to current line";
        };
      }

      {
        mode = "v";
        key = "<";
        action = "<gv";
        options = {
          silent = true;
          desc = "Indent while remaining in visual mode.";
        };
      }

      {
        mode = "v";
        key = ">";
        action = ">gv";
        options = {
          silent = true;
          desc = "Indent while remaining in visual mode.";
        };
      }

      {
        mode = "n";
        key = "<C-d>";
        action = "<C-d>zz";
        options = {
          silent = true;
          desc = "Allow <C-d> and <C-u> to keep the cursor in the middle";
        };
      }

      {
        mode = "n";
        key = "<C-u>";
        action = "<C-u>zz";
        options = {
          desc = "Allow C-d and C-u to keep the cursor in the middle";
        };
      }

      # Remap for dealing with word wrap and adding jumps to the jumplist.
      {
        mode = "n";
        key = "j";
        action.__raw =
          "\n        [[(v:count > 1 ? 'm`' . v:count : 'g') . 'j']]\n      ";
        options = {
          expr = true;
          desc =
            "Remap for dealing with word wrap and adding jumps to the jumplist.";
        };
      }

      {
        mode = "n";
        key = "k";
        action.__raw =
          "\n        [[(v:count > 1 ? 'm`' . v:count : 'g') . 'k']]\n      ";
        options = {
          expr = true;
          desc =
            "Remap for dealing with word wrap and adding jumps to the jumplist.";
        };
      }

      {
        mode = "n";
        key = "n";
        action = "nzzzv";
        options = { desc = "Allow search terms to stay in the middle"; };
      }

      {
        mode = "n";
        key = "N";
        action = "Nzzzv";
        options = { desc = "Allow search terms to stay in the middle"; };
      }

      # Paste stuff without saving the deleted word into the buffer
      {
        mode = "x";
        key = "<leader>p";
        action = ''"_dP'';
        options = { desc = "Deletes to void register and paste over"; };
      }

      # Copy stuff to system clipboard with <leader> + y or just y to have it just in vim
      {
        mode = [ "n" "v" ];
        key = "<leader>y";
        action = ''"+y'';
        options = { desc = "Copy to system clipboard"; };
      }

      {
        mode = [ "n" "v" ];
        key = "<leader>Y";
        action = ''"+Y'';
        options = { desc = "Copy to system clipboard"; };
      }

      # Delete to void register
      {
        mode = [ "n" "v" ];
        key = "<leader>D";
        action = ''"_d'';
        options = { desc = "Delete to void register"; };
      }

      # <C-c> instead of pressing esc just because
      {
        mode = "i";
        key = "<C-c>";
        action = "<Esc>";
      }

      # CHANGED: Removed conflicting <C-f> binding

      # Set highlight on search, but clear on pressing <Esc> in normal mode
      {
        mode = "n";
        key = "<Esc>";
        action = "<cmd>nohlsearch<CR>";
      }

      # Exit terminal mode with Escape key
      {
        mode = "t";
        key = "<Esc><Esc>";
        action = "<C-\\><C-n>";
        options = { desc = "Exit terminal mode"; };
      }

      # Buffer navigation - use leader instead of shift-h/l that might conflict
      {
        mode = "n";
        key = "<leader>bn";
        action = "<cmd>BufferLineCycleNext<cr>";
        options = { desc = "Next buffer"; };
      }
      {
        mode = "n";
        key = "<leader>bp";
        action = "<cmd>BufferLineCyclePrev<cr>";
        options = { desc = "Previous buffer"; };
      }
    ];
  };
}
