-- ============================================================================
-- Configuration for LLM tools.
-- Plugin Configuration: CodeCompanion
-- ============================================================================

return {
  {
    "carlos-algms/agentic.nvim",
    --- @type agentic.PartialUserConfig
    opts = {
      -- Any ACP-compatible provider works. Built-in: "claude-agent-acp" | "gemini-acp" | "codex-acp" | "opencode-acp" | "cursor-acp" | "copilot-acp" | "auggie-acp" | "mistral-vibe-acp" | "cline-acp" | "goose-acp" | "kiro-acp" | "pi-acp"
      provider = "cursor-acp", -- setting the name here is all you need to get started
    },
    keys = {
      {
        "<leader>ta",
        function() require("agentic").toggle() end,
        mode = { "n", "v", "i" },
        desc = "Toggle Agentic Chat"
      },
      {
        "<leader>tf",
        function()
          local preferred = {
            "AgenticInput",
            "AgenticChat",
            "AgenticCode",
            "AgenticFiles",
            "AgenticDiagnostics",
          }
          local wins = vim.api.nvim_tabpage_list_wins(0)
          for _, wanted in ipairs(preferred) do
            for _, win in ipairs(wins) do
              local buf = vim.api.nvim_win_get_buf(win)
              if vim.bo[buf].filetype == wanted then
                vim.api.nvim_set_current_win(win)
                return
              end
            end
          end
          vim.notify("No Agentic window found in current tab", vim.log.levels.INFO)
        end,
        mode = "n",
        desc = "Focus Agentic window",
      },
    },
  },
  {
    "olimorris/codecompanion.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
    event = "VeryLazy",
    keys = {
      {
        "<leader>tc",
        "<cmd>CodeCompanionChat Toggle<cr>",
        mode = { "n", "v" },
        desc = "Toggle CodeCompanion Chat",
      },
      {
        -- Heavy sessions repaint poorly in the embedded terminal; resume them
        -- in a native terminal (tmux window, or a configured emulator) instead.
        "<leader>tr",
        function()
          local cwd = vim.fn.getcwd()
          if vim.env.TMUX and vim.env.TMUX ~= "" then
            vim.fn.jobstart(
              { "tmux", "new-window", "-c", cwd, "-n", "cursor-agent", "agent", "--resume" },
              { detach = true }
            )
            vim.notify("cursor-agent --resume opened in a new tmux window", vim.log.levels.INFO)
            return
          end
          -- Fallback: a user-configured terminal emulator command prefix, e.g.
          --   vim.g.codecompanion_external_terminal = { "wezterm", "start", "--" }
          --   vim.g.codecompanion_external_terminal = { "kitty" }
          local term = vim.g.codecompanion_external_terminal
          if type(term) == "table" and #term > 0 then
            local cmd = vim.deepcopy(term)
            vim.list_extend(cmd, { "agent", "--resume" })
            vim.fn.jobstart(cmd, { detach = true, cwd = cwd })
            vim.notify("cursor-agent --resume opened in external terminal", vim.log.levels.INFO)
            return
          end
          vim.notify(
            "No external terminal available. Run inside tmux, or set "
              .. "vim.g.codecompanion_external_terminal (e.g. { 'wezterm', 'start', '--' }).",
            vim.log.levels.WARN
          )
        end,
        mode = "n",
        desc = "Resume cursor-agent (external terminal)",
      },
    },
    config = function()
      local spinner = require("plugins.code-companion.spinner")
      spinner:init()

      -- The CLI terminal replays huge transcripts on `--resume`; the default
      -- scrollback (10000) trims mid-replay and desyncs the agent's TUI redraw,
      -- causing the endless reload. Keep the full history for CLI terminals.
      vim.api.nvim_create_autocmd("TermOpen", {
        group = vim.api.nvim_create_augroup("codecompanion_cli_term", { clear = true }),
        callback = function(args)
          if vim.bo[args.buf].filetype == "codecompanion_cli" then
            vim.bo[args.buf].scrollback = 100000
          end
        end,
      })

      require("codecompanion").setup({
        opts = {
          log_level = "DEBUG",
        },
        interactions = {
          chat = {
            adapter = {
              name = "cursor_cli",
            },
            keymaps = {
              send = {
                modes = { n = "<C-x>", i = "<C-x>" },
                callback = function(chat)
                  vim.cmd("stopinsert")
                  chat:submit()
                  chat:add_buf_message({ role = "llm", content = "" })
                end,
                index = 1,
                description = "Send",
                opts = {},
              },
            },
          },
          cli = {
            agent = "cursor",
            agents = {
              cursor = {
                cmd = "agent",
                description = "Cursor cli",
                provider = "terminal",
              },
            },
          },
        },
        display = {
          -- The CLI buffer is a terminal running a full-screen TUI. It would
          -- otherwise inherit the chat window's markdown options (wrap/linebreak/
          -- breakindent), which desync the agent's line math. Force terminal-safe
          -- options instead.
          cli = {
            window = {
              opts = {
                wrap = false,
                linebreak = false,
                breakindent = false,
                number = false,
                relativenumber = false,
                signcolumn = "no",
              },
            },
          },
          diff = {
            enabled = true,
          },
          chat = {
            separator = "─",
            show_context = true,
            show_header_separator = true,
            show_token_count = true,
            show_tools_processing = true,
            icons = {
              buffer_sync_all = "󰪴 ",
              buffer_sync_diff = " ",
              chat_context = " ",
              chat_fold = " ",
              tool_pending = "  ",
              tool_in_progress = "  ",
              tool_failure = "  ",
              tool_success = "  ",
            },
            window = {
              buflisted = true, -- List the chat buffer in the buffer list?
              sticky = false, -- Chat window follows when switching tabs (ignored when `pertab` is true)
              pertab = true, -- Treat each tab as having its own chat window?

              layout = "buffer", -- float|vertical|horizontal|tab|buffer
              full_height = true, -- for vertical layout
              position = nil, -- left|right|top|bottom (nil will default depending on vim.opt.splitright|vim.opt.splitbelow)

              -- NOTE: You can set these to 0 for auto width/height
              width = 0, ---@return number|fun(): number
              height = 0, ---@return number|fun(): number

              border = "single",
              relative = "editor",

              -- Ensure that long paragraphs of markdown are wrapped
              opts = {
                breakindent = true,
                linebreak = true,
                wrap = true,
              },
            },
          },
        },
      })
    end,
  },
}
