{ lib, config, ... }: {
  options = { alpha.enable = lib.mkEnableOption "Enable alpha module"; };
  config = lib.mkIf config.alpha.enable {
    plugins.alpha = {
      enable = true;
      theme = null;
      settings.layout = let
        padding = val: {
          type = "padding";
          inherit val;
        };
      in [
        (padding 4)
        {
          opts = {
            hl = "AlphaHeader";
            position = "center";
          };
          type = "text";
          val = [
            "                                            _.--\"\"-._                      "
            "                                          .\"  NEVER  \".                    "
            "                                  /(     /KILL YOURSELF|      )\\           "
            "                                 (  \\__..'--   -   -- -'\"\"-.-'  )          "
            "                                  '.     l_..-------.._l      .'           "
            "                                    \"-.__.||_.-'v'-._||`\"----\"             "
            "                                          l._       _.'                    "
            "                                            l`^^'^^'j                      "
            "  .   *   ..  . *  *                     _   \\_____/     _                 "
            "*  * @()Ooc()*   o  .                   l `--__)-'(__.--' |                "
            "    (Q@*0CG*O()  ____                   | /`---``-----'\"1 |  ,-----.       "
            "   |\\_________/|/ ___ \\                 )/  `--' '---'   \\'-'  ___  `-.    "
            "   |  |  |  |  | /   | \\               //  `-'  '`----'  /  ,-'   I`.  \\   "
            "   |  |  |  |  | |  _ L |_            //  `-.-.'`-----' /  /  |   |  `. \\  "
            "   |  |  |  |  | | '._' / \\         _/(   `/   )- ---' ;  /__.J   L.__.\\ : "
            "   |  |  |  |  | |  `._;/7(-.......'  /        ) (     |  |            | | "
            "   |  |  |  |  | |  `._;l _'--------_/        )-'/     :  |___.    _._./ ; "
            "   |  |  |  |  | |    | |                 .__ )-'\\  __  \\  \\  I   1   / /  "
            "   |  |  |  |  | \\__  | /                /   `-\\-(-'   \\ \\  `.|   | ,' /   "
            "   |  |  |  |  |\\______/                 \\__  `-'    __/  `-. `---'',-'    "
            "   |\\_|__|__|_/|                            )-._.-- (        `-----'       "
            "    \\_________/                            )(  l\\ o ('                     "
          ];
        }
        (padding 2)
        {
          type = "button";
          val = "  Find File";
          on_press = {
            __raw = "function() require('telescope.builtin').find_files() end";
          };
          opts = {
            # hl = "comment";
            keymap = [
              "n"
              "f"
              ":Telescope find_files <CR>"
              {
                noremap = true;
                silent = true;
                nowait = true;
              }
            ];
            shortcut = "f";

            position = "center";
            cursor = 3;
            width = 38;
            align_shortcut = "right";
            hl_shortcut = "Keyword";
          };
        }
        (padding 1)
        {
          type = "button";
          val = "  New File";
          on_press = { __raw = "function() vim.cmd[[ene]] end"; };
          opts = {
            # hl = "comment";
            keymap = [
              "n"
              "n"
              ":ene <BAR> startinsert <CR>"
              {
                noremap = true;
                silent = true;
                nowait = true;
              }
            ];
            shortcut = "n";

            position = "center";
            cursor = 3;
            width = 38;
            align_shortcut = "right";
            hl_shortcut = "Keyword";
          };
        }
        (padding 1)
        {
          type = "button";
          val = "󰈚  Recent Files";
          on_press = {
            __raw = "function() require('telescope.builtin').oldfiles() end";
          };
          opts = {
            # hl = "comment";
            keymap = [
              "n"
              "r"
              ":Telescope oldfiles <CR>"
              {
                noremap = true;
                silent = true;
                nowait = true;
              }
            ];
            shortcut = "r";

            position = "center";
            cursor = 3;
            width = 38;
            align_shortcut = "right";
            hl_shortcut = "Keyword";
          };
        }
        (padding 1)
        {
          type = "button";
          val = "󰈭  Find Word";
          on_press = {
            __raw = "function() require('telescope.builtin').live_grep() end";
          };
          opts = {
            # hl = "comment";
            keymap = [
              "n"
              "g"
              ":Telescope live_grep <CR>"
              {
                noremap = true;
                silent = true;
                nowait = true;
              }
            ];
            shortcut = "g";

            position = "center";
            cursor = 3;
            width = 38;
            align_shortcut = "right";
            hl_shortcut = "Keyword";
          };
        }
        (padding 1)
        {
          type = "button";
          val = "  Restore Session";
          on_press = {
            __raw = "function() require('persistence').load() end";
          };
          opts = {
            # hl = "comment";
            keymap = [
              "n"
              "s"
              ":lua require('persistence').load()<cr>"
              {
                noremap = true;
                silent = true;
                nowait = true;
              }
            ];
            shortcut = "s";

            position = "center";
            cursor = 3;
            width = 38;
            align_shortcut = "right";
            hl_shortcut = "Keyword";
          };
        }
        (padding 1)
        {
          type = "button";
          val = "  Quit Neovim";
          on_press = { __raw = "function() vim.cmd[[qa]] end"; };
          opts = {
            # hl = "comment";
            keymap = [
              "n"
              "q"
              ":qa<CR>"
              {
                noremap = true;
                silent = true;
                nowait = true;
              }
            ];
            shortcut = "q";

            position = "center";
            cursor = 3;
            width = 38;
            align_shortcut = "right";
            hl_shortcut = "Keyword";
          };
        }
      ];
    };

    extraConfigLua = ''
      do
        -- ── helpers ──────────────────────────────────────────────────────────
        local function lerp(a, b, t) return math.floor(a + (b - a) * t) end
        local function to_rgb(n)
          return math.floor(n / 0x10000) % 256,
                 math.floor(n / 0x100)   % 256,
                 n % 256
        end

        -- ── wave gradient: dark grey → white → yellow → back ─────────────
        local key_colors = {
          0x4a4a4a, 0x7a7a7a, 0xaaaaaa,
          0xdddddd, 0xffffff,
          0xfff0a0, 0xffd700,
          0xaaaaaa, 0x4a4a4a,
        }
        local steps    = 32
        local col_step = 4

        local wave_hls = {}
        do
          local n = #key_colors - 1
          for i = 0, steps - 1 do
            local t   = i / steps * n
            local idx = math.floor(t)
            local fr  = t - idx
            local r1,g1,b1 = to_rgb(key_colors[idx+1])
            local r2,g2,b2 = to_rgb(key_colors[idx+2])
            local name = "AlphaWave" .. i
            vim.api.nvim_set_hl(0, name, { fg = string.format("#%02x%02x%02x",
              lerp(r1,r2,fr), lerp(g1,g2,fr), lerp(b1,b2,fr)) })
            wave_hls[i] = name
          end
        end

        -- ── bubble colours ────────────────────────────────────────────────
        local bub_hls = { "AlphaBub1", "AlphaBub2", "AlphaBub3" }
        vim.api.nvim_set_hl(0, "AlphaBub1", { fg = "#ffffff", bold = true })
        vim.api.nvim_set_hl(0, "AlphaBub2", { fg = "#ffe8a0" })
        vim.api.nvim_set_hl(0, "AlphaBub3", { fg = "#aaaaaa" })

        local bub_chars   = { ".", "*", "o", "O" }
        -- cauldron area in art-relative coords (0-indexed)
        local bub_col_min = 6
        local bub_col_max = 13
        local bub_src_row = 10   -- spawn row (bottom of cauldron, art-relative)
        local bub_top_row = 6    -- row at which bubble disappears

        local function new_bubble(random_height)
          local ar = random_height
            and (bub_top_row + math.random(0, bub_src_row - bub_top_row))
            or  bub_src_row
          return {
            frow  = ar,
            col   = bub_col_min + math.random(0, bub_col_max - bub_col_min),
            char  = bub_chars[math.random(#bub_chars)],
            hl    = bub_hls[math.random(#bub_hls)],
            speed = 0.04 + math.random() * 0.08,
          }
        end

        -- ── namespaces & shared state ─────────────────────────────────────
        local wave_ns   = vim.api.nvim_create_namespace("alpha_wave")
        local bub_ns    = vim.api.nvim_create_namespace("alpha_bubbles")
        local ascii_start = 4
        local ascii_lines = 22
        local art_width   = 74
        local frame = 0

        vim.api.nvim_create_autocmd("FileType", {
          pattern = "alpha",
          callback = function()
            local buf = vim.api.nvim_get_current_buf()
            local win = vim.api.nvim_get_current_win()

            -- seed + init bubbles
            math.randomseed(vim.uv.now())
            local bubbles = {}
            for _ = 1, 14 do
              table.insert(bubbles, new_bubble(true))
            end

            local timer = vim.uv.new_timer()
            timer:start(0, 60, vim.schedule_wrap(function()
              if not vim.api.nvim_buf_is_valid(buf) then
                timer:stop(); timer:close(); return
              end
              frame = frame + 1

              -- recalculate centering offset every frame
              local win_width = vim.api.nvim_win_is_valid(win)
                and vim.api.nvim_win_get_width(win) or 120
              local offset = math.max(0, math.floor((win_width - art_width) / 2))

              -- wave (spans full window width so it fills on any size)
              vim.api.nvim_buf_clear_namespace(buf, wave_ns, 0, -1)
              for i = 0, ascii_lines - 1 do
                local row = ascii_start + i
                local j = 0
                while j < win_width do
                  local ci = (frame + i + math.floor(j / col_step)) % steps
                  local je = j + 1
                  while je < win_width
                    and (frame + i + math.floor(je / col_step)) % steps == ci do
                    je = je + 1
                  end
                  vim.api.nvim_buf_add_highlight(buf, wave_ns, wave_hls[ci], row, j, je)
                  j = je
                end
              end

              -- bubbles (column relative to centered art)
              vim.api.nvim_buf_clear_namespace(buf, bub_ns, 0, -1)
              for _, b in ipairs(bubbles) do
                b.frow = b.frow - b.speed
                if b.frow < bub_top_row then
                  local nb = new_bubble(false)
                  b.frow = nb.frow; b.col = nb.col
                  b.char = nb.char; b.hl  = nb.hl; b.speed = nb.speed
                end
                vim.api.nvim_buf_set_extmark(buf, bub_ns,
                  ascii_start + math.floor(b.frow), 0, {
                    virt_text         = {{ b.char, b.hl }},
                    virt_text_win_col = offset + b.col,
                    priority          = 300,
                  })
              end
            end))

            vim.api.nvim_create_autocmd("BufLeave", {
              buffer = buf, once = true,
              callback = function() timer:stop(); timer:close() end,
            })
          end,
        })
      end
    '';
  };
}
