{ lib, config, ... }: {
  options = { set.enable = lib.mkEnableOption "Enable set module"; };
  config = lib.mkIf config.set.enable {
    opts = {
      # Enable relative line numbers
      number = true;
      relativenumber = true;

      # Set tabs to 2 spaces
      tabstop = 2;
      softtabstop = 2;
      showtabline = 2;
      expandtab = true;

      # Enable auto indenting and set it to spaces
      smartindent = true;
      shiftwidth = 2;

      # Enable smart indenting (see https://stackoverflow.com/questions/1204149/smart-wrap-in-vim)
      breakindent = true;

      # Enable incremental searching
      hlsearch = true;
      incsearch = true;

      # Enable text wrap
      wrap = true;

      # Better splitting
      splitbelow = true;
      splitright = true;

      # Enable mouse mode
      mouse = "a"; # Mouse

      # Enable ignorecase + smartcase for better searching
      ignorecase = true;
      smartcase = true; # Don't ignore case with capitals
      grepprg = "rg --vimgrep";
      grepformat = "%f:%l:%c:%m";

      # Decrease updatetime
      updatetime = 50; # faster completion (4000ms default)

      # Set completeopt to have a better completion experience
      completeopt = [ "menuone" "noselect" "noinsert" ]; # mostly just for cmp

      # Enable persistent undo history
      swapfile = false;
      backup = false;
      undofile = true;

      # Enable 24-bit colors
      termguicolors = true;

      # Enable the sign column to prevent the screen from jumping
      signcolumn = "yes";

      # Enable cursor line highlight
      cursorline = false; # Highlight the line where the cursor is located

      # Set fold settings
      # These options were recommended by nvim-ufo
      # See: https://github.com/kevinhwang91/nvim-ufo#minimal-configuration
      foldcolumn = "0";
      foldlevel = 99;
      foldlevelstart = 99;
      foldenable = true;
      foldmethod = "expr";
      foldexpr = "v:lua.vim.treesitter.foldexpr()";

      # Always keep 8 lines above/below cursor unless at start/end of file
      scrolloff = 8;

      # Place a column line
      colorcolumn = "80";

      # Reduce which-key timeout 
      timeoutlen = 1000;

      # Set encoding type
      encoding = "utf-8";
      fileencoding = "utf-8";

      # Change cursor options
      guicursor = [
        "n-v-c:block" # Normal, visual, command-line: block cursor
        "i-ci-ve:block" # Insert, command-line insert, visual-exclude: vertical bar cursor with block cursor, use "ver25" for 25% width
        "r-cr:hor20" # Replace, command-line replace: horizontal bar cursor with 20% height
        "o:hor50" # Operator-pending: horizontal bar cursor with 50% height
        "a:blinkwait700-blinkoff400-blinkon250-Cursor/lCursor" # All modes: blinking settings
        "sm:block-blinkwait175-blinkoff150-blinkon175" # Showmatch: block cursor with specific blinking settings
      ];

      # Enable chars list
      list = true; # Show invisible characters (tabs, eol, ...)
      listchars =
        "eol:↲,tab:|->,lead:·,space: ,trail:•,extends:→,precedes:←,nbsp:␣";

      # Minimum space in the neovim command line for displaying messages
      cmdheight = 1;

      # We don't need to see things like INSERT anymore
      showmode = false;

      # Maximum number of items to show in the popup menu (0 means "use available screen space")
      pumheight = 0;

      # Use conform-nvim for gq formatting. ('formatexpr' is set to vim.lsp.formatexpr(), so you can format lines via gq if the language server supports it)
      formatexpr = "v:lua.require'conform'.formatexpr()";

      laststatus = 3; # (https://neovim.io/doc/user/options.html#'laststatus')

      inccommand =
        "split"; # (https://neovim.io/doc/user/options.html#'inccommand')
    };

    highlight = {
      Normal = { bg = "none"; };
      NormalFloat = { bg = "none"; };
      NormalNC = { bg = "none"; };
      SignColumn = { bg = "none"; };
      LineNr = { bg = "none"; };
      CursorLineNr = { bg = "none"; };
    };

    extraConfigLua = ''
      -- Window mode implementation
      _G.window_mode_active = false
      _G.window_mode_timer = nil
      _G.window_mode_bufnr = nil
      _G.window_mode_namespace = vim.api.nvim_create_namespace('window_mode')

      function _G.EnterWindowMode()
        if _G.window_mode_active then
          -- Reset timer if already in mode
          if _G.window_mode_timer then
            vim.fn.timer_stop(_G.window_mode_timer)
          end
          _G.window_mode_timer = vim.fn.timer_start(5000, function()
            ExitWindowMode()
          end)
          return
        end
        
        _G.window_mode_active = true
        _G.window_mode_bufnr = vim.api.nvim_get_current_buf()
        
        -- Show notification
        if pcall(require, 'notify') then
          require('notify')("Window Mode Active - hjkl/arrows to navigate, m=maximize, q=quit", "info", { 
            title = "Window Mode",
            timeout = 1000,
          })
        else
          vim.notify("Window Mode: hjkl/arrows (q to quit)", vim.log.levels.INFO)
        end
        
        -- Set up temporary keymaps with callback to stay in mode
        local function make_stay_in_mode(cmd)
          return function()
            vim.cmd(cmd)
            -- Reset the auto-exit timer after each action
            if _G.window_mode_timer then
              vim.fn.timer_stop(_G.window_mode_timer)
            end
            _G.window_mode_timer = vim.fn.timer_start(5000, function()
              ExitWindowMode()
            end)
          end
        end
        
        local function make_lua_stay_in_mode(func)
          return function()
            func()
            -- Reset the auto-exit timer after each action
            if _G.window_mode_timer then
              vim.fn.timer_stop(_G.window_mode_timer)
            end
            _G.window_mode_timer = vim.fn.timer_start(5000, function()
              ExitWindowMode()
            end)
          end
        end
        
        local opts = { noremap = true, silent = true }
        
        -- Navigation with hjkl
        vim.keymap.set('n', 'h', make_stay_in_mode('wincmd h'), opts)
        vim.keymap.set('n', 'j', make_stay_in_mode('wincmd j'), opts)
        vim.keymap.set('n', 'k', make_stay_in_mode('wincmd k'), opts)
        vim.keymap.set('n', 'l', make_stay_in_mode('wincmd l'), opts)
        
        -- Navigation with arrows
        vim.keymap.set('n', '<Left>', make_stay_in_mode('wincmd h'), opts)
        vim.keymap.set('n', '<Down>', make_stay_in_mode('wincmd j'), opts)
        vim.keymap.set('n', '<Up>', make_stay_in_mode('wincmd k'), opts)
        vim.keymap.set('n', '<Right>', make_stay_in_mode('wincmd l'), opts)
        
        -- Window operations
        vim.keymap.set('n', 'm', make_lua_stay_in_mode(_G.ToggleMaximize), opts)
        vim.keymap.set('n', 's', make_stay_in_mode('wincmd s'), opts)
        vim.keymap.set('n', 'v', make_stay_in_mode('wincmd v'), opts)
        vim.keymap.set('n', 'c', make_stay_in_mode('wincmd c'), opts)
        vim.keymap.set('n', 'o', make_stay_in_mode('wincmd o'), opts)
        vim.keymap.set('n', '=', make_stay_in_mode('wincmd ='), opts)
        
        -- Resize operations
        vim.keymap.set('n', '+', make_stay_in_mode('wincmd +'), opts)
        vim.keymap.set('n', '-', make_stay_in_mode('wincmd -'), opts)
        vim.keymap.set('n', '>', make_stay_in_mode('wincmd >'), opts)
        vim.keymap.set('n', '<', make_stay_in_mode('wincmd <'), opts)
        
        -- Exit window mode
        vim.keymap.set('n', 'q', _G.ExitWindowMode, opts)
        vim.keymap.set('n', '<Esc>', _G.ExitWindowMode, opts)
        
        -- Start auto-exit timer
        _G.window_mode_timer = vim.fn.timer_start(5000, function()
          ExitWindowMode()
        end)
      end

      function _G.ExitWindowMode()
        if not _G.window_mode_active then
          return
        end
        
        _G.window_mode_active = false
        
        -- Stop timer
        if _G.window_mode_timer then
          vim.fn.timer_stop(_G.window_mode_timer)
          _G.window_mode_timer = nil
        end
        
        -- Clear all temporary keymaps
        local keys = {'h', 'j', 'k', 'l', '<Left>', '<Down>', '<Up>', '<Right>', 
                      'm', 's', 'v', 'c', 'o', '=', '+', '-', '>', '<', 'q', '<Esc>'}
        for _, key in ipairs(keys) do
          pcall(vim.keymap.del, 'n', key)
        end
        
        if pcall(require, 'notify') then
          require('notify')("Window Mode Exited", "info", { 
            title = "Window Mode",
            timeout = 500,
          })
        end
      end

      -- Keep the ToggleMaximize function from before
      _G.window_sizes = {}
      _G.is_maximized = false

      function _G.ToggleMaximize()
        if _G.is_maximized then
          -- Restore saved sizes
          for winnr, sizes in pairs(_G.window_sizes) do
            if vim.api.nvim_win_is_valid(winnr) then
              vim.api.nvim_win_set_width(winnr, sizes.width)
              vim.api.nvim_win_set_height(winnr, sizes.height)
            end
          end
          _G.window_sizes = {}
          _G.is_maximized = false
        else
          -- Save current sizes and maximize
          _G.window_sizes = {}
          local current_win = vim.api.nvim_get_current_win()
          for _, winnr in ipairs(vim.api.nvim_list_wins()) do
            if vim.api.nvim_win_is_valid(winnr) then
              _G.window_sizes[winnr] = {
                width = vim.api.nvim_win_get_width(winnr),
                height = vim.api.nvim_win_get_height(winnr)
              }
            end
          end
          vim.cmd('wincmd _')
          vim.cmd('wincmd |')
          _G.is_maximized = true
        end
      end

      local opt = vim.opt
      local g = vim.g
      local o = vim.o

      -- Set up Fish filetype detection
      vim.api.nvim_create_autocmd({"BufRead", "BufNewFile"}, {
        pattern = {"*.fish"},
        callback = function()
          vim.bo.filetype = "fish"
        end
      })

      -- Neovide
      if g.neovide then
        g.neovide_fullscreen = false
        g.neovide_hide_mouse_when_typing = false
        g.neovide_refresh_rate = 165
        g.neovide_cursor_vfx_mode = "ripple"
        g.neovide_cursor_animate_command_line = true
        g.neovide_cursor_animate_in_insert_mode = true
        g.neovide_cursor_vfx_particle_lifetime = 5.0
        g.neovide_cursor_vfx_particle_density = 14.0
        g.neovide_cursor_vfx_particle_speed = 12.0
        g.neovide_transparency = 0.8

        -- Neovide Fonts
        o.guifont = "JetBrainsMono Nerd Font:h14:Medium:i"
      end

      -- Force transparency for all backgrounds
      vim.api.nvim_set_hl(0, "Normal", { bg = "NONE" })
      vim.api.nvim_set_hl(0, "NormalFloat", { bg = "NONE" })
      vim.api.nvim_set_hl(0, "NormalNC", { bg = "NONE" })
      vim.api.nvim_set_hl(0, "SignColumn", { bg = "NONE" })
      vim.api.nvim_set_hl(0, "EndOfBuffer", { bg = "NONE" })
      vim.api.nvim_set_hl(0, "LineNr", { bg = "NONE" })
      vim.api.nvim_set_hl(0, "Folded", { bg = "NONE" })
      vim.api.nvim_set_hl(0, "NonText", { bg = "NONE" })
      vim.api.nvim_set_hl(0, "SpecialKey", { bg = "NONE" })
      vim.api.nvim_set_hl(0, "VertSplit", { bg = "NONE" })
      vim.api.nvim_set_hl(0, "StatusLine", { bg = "NONE" })
      vim.api.nvim_set_hl(0, "StatusLineNC", { bg = "NONE" })
      vim.api.nvim_set_hl(0, "WinBar", { bg = "NONE" })
      vim.api.nvim_set_hl(0, "WinBarNC", { bg = "NONE" })
    '';
  };
}
