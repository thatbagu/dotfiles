{ lib, config, ... }: {
  options = {
    codecompanion = {
      enable = lib.mkEnableOption "Enable CodeCompanion module";
      chatPosition = lib.mkOption {
        type = lib.types.enum [ "vertical" "horizontal" "float" "buffer" ];
        default = "vertical";
        description = "Position of the chat buffer";
      };
      chatWidth = lib.mkOption {
        type = lib.types.float;
        default = 0.45;
        description = "Width of the chat buffer (when using vertical layout)";
      };
      defaultAdapter = lib.mkOption {
        type = lib.types.str;
        default = "anthropic";
        description = "Default adapter to use for chat";
      };
      keyPrefix = lib.mkOption {
        type = lib.types.str;
        default = "a";
        description = "Leader key prefix for CodeCompanion commands";
      };
    };
  };

  config = lib.mkIf config.codecompanion.enable {
    # Enable required dependencies
    plenary.enable = true;
    cmp.enable = true;
    telescope-nvim.enable = true;
    web-devicons.enable = true;
    treesitter-nvim.enable = true;

    # CodeCompanion configuration
    plugins.codecompanion = { enable = true; };

    # Combined extraConfigLua with all configuration
    extraConfigLua = ''
            -- Create directory for debugging logs
            local log_dir = vim.fn.stdpath("cache") .. "/codecompanion"
            vim.fn.mkdir(log_dir, "p")
            
            -- CodeCompanion full configuration
            require("codecompanion").setup({
              strategies = {
                chat = {
                  adapter = "${config.codecompanion.defaultAdapter}",
                  roles = {
                    llm = "Claude", -- Static name instead of dynamic function
                    user = "Me"
                  },
                  opts = {
                    auto_submit_errors = true, -- Automatically submit errors back to LLM
                    auto_submit_success = true, -- Automatically submit success messages back to LLM
                    prompt_decorator = function(message, adapter, context)
                      -- Add a clear instruction for editing
                      if message:match("@editor") then
                        return "I need you to make direct edits to my code. " .. message
                      end
                      return message
                    end,
                  },
                  -- Enable variables for sharing buffer context
                  variables = {
                    ["buffer"] = {
                      callback = "strategies.chat.variables.buffer",
                      description = "Share the current buffer",
                      opts = {
                        contains_code = true,
                      },
                    },
                    ["lsp"] = {
                      callback = "strategies.chat.variables.lsp",
                      description = "Share LSP information",
                      opts = {
                        contains_code = true,
                      },
                    },
                    ["viewport"] = {
                      callback = "strategies.chat.variables.viewport",
                      description = "Share visible buffers",
                      opts = {
                        contains_code = true,
                      },
                    },
                    -- Custom buffer shortcuts for specific buffers
                    ["all_buffers"] = {
                      callback = function()
                        local bufs = {}
                        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
                          if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].buftype == "" and vim.bo[buf].filetype ~= "CodeCompanion" then
                            table.insert(bufs, { bufnr = buf, text = vim.api.nvim_buf_get_lines(buf, 0, -1, false) })
                          end
                        end
                        
                        local result = ""
                        for _, buf in ipairs(bufs) do
                          local name = vim.api.nvim_buf_get_name(buf.bufnr)
                          if name and name ~= "" then
                            result = result .. "--- " .. name .. " ---\\n"
                            result = result .. table.concat(buf.text, "\\n") .. "\\n\\n"
                          end
                        end
                        
                        return result
                      end,
                      description = "Share all open buffers",
                      opts = {
                        contains_code = true,
                      },
                    },
                  },
                  -- Enable slash commands for context sharing
                  slash_commands = {
                    ["buffer"] = {
                      callback = "strategies.chat.slash_commands.buffer",
                      description = "Select a buffer to include",
                      opts = {
                        provider = "telescope", -- Can be "default", "telescope", "mini_pick", etc.
                        contains_code = true,
                        multiple = true, -- Allow selecting multiple buffers
                      },
                    },
                    ["file"] = {
                      callback = "strategies.chat.slash_commands.file",
                      description = "Select a file using Telescope",
                      opts = {
                        provider = "telescope",
                        contains_code = true,
                        multiple = true, -- Allow selecting multiple files
                      },
                    },
                    ["symbols"] = {
                      callback = "strategies.chat.slash_commands.symbols",
                      description = "Select symbols from a file",
                      opts = {
                        provider = "telescope",
                        contains_code = true,
                      },
                    },
                    ["multi_buffer"] = {
                      callback = function(chat)
                        -- Use telescope to select multiple buffers
                        require("telescope.builtin").buffers({
                          attach_mappings = function(prompt_bufnr, map)
                            -- Enable multi-selection
                            local actions = require("telescope.actions")
                            local action_state = require("telescope.actions.state")
                            
                            actions.select_default:replace(function()
                              local selections = {}
                              local current_picker = action_state.get_current_picker(prompt_bufnr)
                              
                              for _, entry in ipairs(current_picker:get_multi_selection()) do
                                table.insert(selections, entry)
                              end
                              
                              if #selections == 0 then
                                -- Add the currently selected item
                                local selection = action_state.get_selected_entry()
                                if selection then
                                  table.insert(selections, selection)
                                end
                              end
                              
                              actions.close(prompt_bufnr)
                              
                              -- Add each selected buffer to the chat
                              for _, selection in ipairs(selections) do
                                local bufnr = selection.bufnr
                                
                                if bufnr and vim.api.nvim_buf_is_valid(bufnr) then
                                  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
                                  local content = table.concat(lines, "\\n")
                                  local bufname = vim.api.nvim_buf_get_name(bufnr)
                                  
                                  -- Add the buffer to the chat
                                  chat:add_reference(
                                    { role = "user", content = content },
                                    "buffer",
                                    bufname
                                  )
                                end
                              end
                            end)
                            
                            -- Keep default mappings
                            return true
                          end,
                          prompt_title = "Select Multiple Buffers",
                        })
                      end,
                      description = "Select multiple buffers to include",
                      opts = {
                        contains_code = true,
                      },
                    },
                  },
                  -- Enable tools for editing code
                  tools = {
                    ["editor"] = {
                      description = "Let the LLM edit your code",
                      callback = "strategies.chat.tools.editor",
                      opts = {
                        requires_approval = false, -- Critical: Disable approval requirement
                      },
                    },
                    ["cmd_runner"] = {
                      description = "Let the LLM run shell commands",
                      callback = "strategies.chat.tools.cmd_runner",
                      opts = {
                        requires_approval = false, -- Disable approval requirement 
                      },
                    },
                    ["files"] = {
                      description = "Let the LLM work with files",
                      callback = "strategies.chat.tools.files",
                      opts = {
                        requires_approval = false, -- Disable approval requirement
                      },
                    },
                    opts = {
                      auto_submit_errors = true, -- Send any errors to the LLM automatically
                      auto_submit_success = true, -- Send any successful output to the LLM automatically
                    },
                    groups = {
                      ["full_stack_dev"] = {
                        description = "Full developer agent with file and command access",
                        system_prompt = "You are a full-stack developer with access to filesystem and terminal",
                        tools = { "editor", "cmd_runner", "files" },
                      },
                    },
                  },
                },
                inline = {
                  adapter = "${config.codecompanion.defaultAdapter}"
                }
              },
              display = {
                chat = {
                  window = {
                    layout = "${config.codecompanion.chatPosition}",
                    width = ${toString config.codecompanion.chatWidth},
                    height = 0.8,
                    full_height = true
                  },
                  auto_scroll = true,
                  show_header_separator = true,
                  show_references = true,
                  show_settings = true,
                  show_token_count = true,
                  start_in_insert_mode = true
                },
                diff = {
                  enabled = false, -- Critical: Disable diff view to allow direct editing
                },
              },
              adapters = {
                anthropic = function()
                  return require("codecompanion.adapters").extend("anthropic", {
                    formatted_name = "Claude", -- Explicitly set the formatted_name
                    schema = {
                      model = {
                        default = "claude-3-7-sonnet-20250219"
                      },
                      temperature = {
                        default = 0.1
                      },
                      max_tokens = {
                        default = 24000 -- Increased from 4096 to handle large contexts
                      },
                      system = {
                        default = ""
                      }
                    },
                    -- Fix for the thinking.budget_tokens issue
                    parameters = {
                      thinking = {
                        enabled = false -- Disable thinking for now to avoid the budget_tokens conflict
                      }
                    }
                  })
                end
              },
              opts = {
                log_level = "DEBUG", -- Enable DEBUG logging to help troubleshoot tool issues
                send_code = true,   -- Make sure code can be sent to the LLM
                system_prompt = function(opts)
                  return [[
      You are an AI programming assistant named "CodeCompanion". You are currently plugged in to the Neovim text editor on a user's machine.

      Your core tasks include:
      - Answering general programming questions.
      - Explaining how the code in a Neovim buffer works.
      - Reviewing the selected code in a Neovim buffer.
      - Generating unit tests for the selected code.
      - Proposing fixes for problems in the selected code.
      - Scaffolding code for a new workspace.
      - Finding relevant code to the user's query.
      - Proposing fixes for test failures.
      - Answering questions about Neovim.
      - Running tools.

      You must:
      - Follow the user's requirements carefully and to the letter.
      - Keep your answers short and impersonal, especially if the user responds with context outside of your tasks.
      - Minimize other prose.
      - Use Markdown formatting in your answers.
      - Include the programming language name at the start of the Markdown code blocks.
      - Avoid including line numbers in code blocks.
      - Avoid wrapping the whole response in triple backticks.
      - Only return code that's relevant to the task at hand. You may not need to return all of the code that the user has shared.
      - Use actual line breaks instead of '\n' in your response to begin new lines.
      - Use '\n' only when you want a literal backslash followed by a character 'n'.
      - All non-code responses must be in ]] .. (opts.language or "English") .. [[.

      When asked to edit code with @editor tool:
      1. MAKE DIRECT EDITS to the buffer. Do not just display the code.
      2. Understand exactly what specific changes are requested.
      3. Apply the requested changes directly to the buffer.
      4. When appropriate, explain the changes you made.

      When given a general task:
      1. Think step-by-step and describe your plan for what to build in pseudocode, written out in great detail, unless asked not to do so.
      2. Output the code in a single code block, being careful to only return relevant code.
      3. You should always generate short suggestions for the next user turns that are relevant to the conversation.
      4. You can only give one reply for each conversation turn.
      ]]
                end
              }
            })
            
            -- Set this global to enable automatic tool execution mode
            vim.g.codecompanion_auto_tool_mode = true
            
            -- Create global function to debug any buffer
            function _G.debug_buffer(bufnr)
              bufnr = bufnr or vim.api.nvim_get_current_buf()
              local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
              local content = table.concat(lines, "\n")
              local name = vim.api.nvim_buf_get_name(bufnr)
              local ft = vim.bo[bufnr].filetype
              
              print("Buffer: " .. bufnr)
              print("Name: " .. name)
              print("Filetype: " .. ft)
              print("Line count: " .. #lines)
              print("First few lines: " .. content:sub(1, 200) .. "...")
              
              return {
                bufnr = bufnr,
                name = name,
                filetype = ft,
                line_count = #lines,
                sample = content:sub(1, 200)
              }
            end
            
            -- Add debugging for editor tool
            vim.api.nvim_create_autocmd("User", {
              pattern = "CodeCompanionTool*",
              callback = function(args)
                -- Log tool events for debugging
                local tool_name = args.data and args.data.name or "unknown"
                local log_file = log_dir .. "/tools.log"
                
                if args.match == "CodeCompanionToolStarted" then
                  local msg = os.date("[%Y-%m-%d %H:%M:%S] ") .. "Tool started: " .. tool_name
                  vim.fn.writefile({msg}, log_file, "a")
                  
                  -- Print notification
                  vim.notify("Tool started: " .. tool_name, vim.log.levels.INFO, {title = "CodeCompanion"})
                elseif args.match == "CodeCompanionToolFinished" then
                  local msg = os.date("[%Y-%m-%d %H:%M:%S] ") .. "Tool finished: " .. tool_name
                  vim.fn.writefile({msg}, log_file, "a")
                  
                  -- Print notification
                  vim.notify("Tool finished: " .. tool_name, vim.log.levels.INFO, {title = "CodeCompanion"})
                end
              end,
            })
            
            -- Add debugging for the editor events
            vim.api.nvim_create_autocmd("User", {
              pattern = "CodeCompanionEdit*",
              callback = function(args)
                local log_file = log_dir .. "/editor.log"
                local msg = os.date("[%Y-%m-%d %H:%M:%S] ") .. args.match .. ": " .. vim.inspect(args.data or {})
                vim.fn.writefile({msg}, log_file, "a")
              end,
            })
            
            -- Add command to toggle auto tool mode
            vim.api.nvim_create_user_command("CodeCompanionToggleAutoToolMode", function()
              vim.g.codecompanion_auto_tool_mode = not vim.g.codecompanion_auto_tool_mode
              local status = vim.g.codecompanion_auto_tool_mode and "enabled" or "disabled"
              vim.notify("Auto tool mode " .. status, vim.log.levels.INFO, {title = "CodeCompanion"})
            end, {})
            
            -- Add shortcut function to share multiple buffers
            function _G.cc_share_multiple_buffers()
              local chat = require("codecompanion").get_chat()
              if not chat then
                -- No active chat, start one and use #all_buffers
                require("codecompanion").chat({ prompt = "#all_buffers ", focus = true })
                return
              end
              -- Use telescope to select multiple buffers
              require("telescope.builtin").buffers({
                attach_mappings = function(prompt_bufnr, map)
                  local actions = require("telescope.actions")
                  local action_state = require("telescope.actions.state")
                  
                  actions.select_default:replace(function()
                    local selections = {}
                    local current_picker = action_state.get_current_picker(prompt_bufnr)
                    
                    for _, entry in ipairs(current_picker:get_multi_selection()) do
                      table.insert(selections, entry)
                    end
                    
                    if #selections == 0 then
                      -- Add the currently selected item
                      local selection = action_state.get_selected_entry()
                      if selection then
                        table.insert(selections, selection)
                      end
                    end
                    
                    actions.close(prompt_bufnr)
                    
                    -- Add each selected buffer to the chat
                    for _, selection in ipairs(selections) do
                      local bufnr = selection.bufnr
                      
                      if bufnr and vim.api.nvim_buf_is_valid(bufnr) then
                        local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
                        local content = table.concat(lines, "\\n")
                        local bufname = vim.api.nvim_buf_get_name(bufnr)
                        
                        -- Add the buffer to the chat
                        chat:add_reference(
                          { role = "user", content = content },
                          "buffer",
                          bufname
                        )
                      end
                    end
                  end)
                  
                  -- Keep default mappings
                  return true
                end,
                prompt_title = "Select Multiple Buffers",
              })
            end
    '';

    # Add keymaps for CodeCompanion, using leader+${config.codecompanion.keyPrefix} namespace to avoid conflicts
    keymaps = [
      # Main chat commands
      {
        mode = [ "n" "v" ];
        key = "<leader>${config.codecompanion.keyPrefix}c";
        action = "<cmd>CodeCompanionChat Toggle<CR>";
        options = {
          silent = true;
          desc = "Toggle CodeCompanion chat";
        };
      }
      {
        mode = [ "n" "v" ];
        key = "<leader>${config.codecompanion.keyPrefix}a";
        action = "<cmd>CodeCompanionActions<CR>";
        options = {
          silent = true;
          desc = "CodeCompanion actions";
        };
      }
      # Code operations
      {
        mode = "v";
        key = "<leader>${config.codecompanion.keyPrefix}e";
        action = "<cmd>CodeCompanion /explain<CR>";
        options = {
          silent = true;
          desc = "Explain code";
        };
      }
      {
        mode = "v";
        key = "<leader>${config.codecompanion.keyPrefix}f";
        action = "<cmd>CodeCompanion /fix<CR>";
        options = {
          silent = true;
          desc = "Fix code";
        };
      }
      {
        mode = "v";
        key = "<leader>${config.codecompanion.keyPrefix}t";
        action = "<cmd>CodeCompanion /tests<CR>";
        options = {
          silent = true;
          desc = "Generate tests";
        };
      }
      {
        mode = "n";
        key = "<leader>${config.codecompanion.keyPrefix}m";
        action = "<cmd>CodeCompanion /commit<CR>";
        options = {
          silent = true;
          desc = "Generate commit message";
        };
      }
      # Auto tool mode toggle
      {
        mode = "n";
        key = "<leader>${config.codecompanion.keyPrefix}ta";
        action = "<cmd>CodeCompanionToggleAutoToolMode<CR>";
        options = {
          silent = true;
          desc = "Toggle auto tool mode";
        };
      }
      # Context sharing commands
      {
        mode = "n";
        key = "<leader>${config.codecompanion.keyPrefix}ib";
        action = "<cmd>CodeCompanionChat #buffer<CR>";
        options = {
          silent = true;
          desc = "Chat with buffer context";
        };
      }
      {
        mode = "n";
        key = "<leader>${config.codecompanion.keyPrefix}iw";
        action = "<cmd>CodeCompanionChat #buffer{watch}<CR>";
        options = {
          silent = true;
          desc = "Chat with watched buffer";
        };
      }
      {
        mode = "n";
        key = "<leader>${config.codecompanion.keyPrefix}il";
        action = "<cmd>CodeCompanionChat #lsp<CR>";
        options = {
          silent = true;
          desc = "Chat with LSP diagnostics";
        };
      }
      {
        mode = "n";
        key = "<leader>${config.codecompanion.keyPrefix}iv";
        action = "<cmd>CodeCompanionChat #viewport<CR>";
        options = {
          silent = true;
          desc = "Chat with viewport context";
        };
      }
      {
        mode = "n";
        key = "<leader>${config.codecompanion.keyPrefix}ia";
        action = "<cmd>CodeCompanionChat #all_buffers<CR>";
        options = {
          silent = true;
          desc = "Chat with all buffers context";
        };
      }
      # Multi-buffer selection - adds all selected buffers as references
      {
        mode = "n";
        key = "<leader>${config.codecompanion.keyPrefix}im";
        action = "<cmd>lua _G.cc_share_multiple_buffers()<CR>";
        options = {
          silent = true;
          desc = "Select multiple buffers for context";
        };
      }
      # Additional keymaps for direct commands
      {
        mode = "n";
        key = "<leader>${config.codecompanion.keyPrefix}s";
        action = "<cmd>CodeCompanionChat<CR>";
        options = {
          silent = true;
          desc = "Start new chat";
        };
      }
      # Extra convenience keymaps for the chat buffer
      {
        mode = "n";
        key = "<leader>${config.codecompanion.keyPrefix}ed";
        action =
          "<cmd>CodeCompanionChat @editor Please review and fix the code in #buffer{watch}<CR>";
        options = {
          silent = true;
          desc = "Ask editor to fix current buffer";
        };
      }
    ];
  };
}
