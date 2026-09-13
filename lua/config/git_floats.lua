-- Floating git diff views: unified patch text and side-by-side vimdiff panes.

local M = {}

local function git_root()
  local out = vim.fn.systemlist({ "git", "rev-parse", "--show-toplevel" })
  if vim.v.shell_error ~= 0 then
    return nil
  end
  return out[1]
end

local function diff_range(base)
  if base:find("%.%.", 1, true) then
    return base
  end
  return base .. "..."
end

local function close_maps(bufs, wins)
  local function close()
    for _, win in ipairs(wins) do
      pcall(vim.api.nvim_win_close, win, true)
    end
  end

  for _, buf in ipairs(bufs) do
    vim.keymap.set("n", "q", close, { buffer = buf, nowait = true, desc = "Close diff" })
    vim.keymap.set("n", "<Esc>", close, { buffer = buf, nowait = true, desc = "Close diff" })
  end
end

---@class GitFloats.UnifiedOpts
---@field staged? boolean Diff the index instead of the working tree.
---@field base? string Revision or range to diff against.
---@field repo? boolean Diff the whole repository instead of the current file.

---Show `git diff` output in a centered floating window.
---@param opts? GitFloats.UnifiedOpts
function M.unified(opts)
  opts = opts or {}

  local root = git_root()
  if not root then
    return vim.notify("Not a git repository", vim.log.levels.WARN)
  end

  local cmd = { "git", "-C", root, "--no-pager", "diff", "--no-color" }
  if opts.staged then
    table.insert(cmd, "--staged")
  end
  if opts.base then
    table.insert(cmd, diff_range(opts.base))
  end

  local scope
  if opts.repo then
    scope = "repository"
  else
    scope = vim.fn.expand("%:t")
    if scope == "" then
      return vim.notify("No file to diff", vim.log.levels.WARN)
    end
    vim.list_extend(cmd, { "--", vim.fn.expand("%:p") })
  end

  local lines = vim.fn.systemlist(cmd)
  if vim.v.shell_error ~= 0 then
    return vim.notify("git diff failed:\n" .. table.concat(lines, "\n"), vim.log.levels.ERROR)
  end
  if #lines == 0 then
    return vim.notify("No changes in " .. scope, vim.log.levels.INFO)
  end

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].filetype = "diff"
  vim.bo[buf].modifiable = false
  vim.bo[buf].bufhidden = "wipe"

  local title_parts = { "git diff" }
  if opts.staged then
    table.insert(title_parts, "--staged")
  end
  if opts.base then
    table.insert(title_parts, diff_range(opts.base))
  end
  table.insert(title_parts, scope)

  local width = math.min(vim.o.columns - 8, 160)
  local height = math.min(vim.o.lines - 6, math.max(#lines + 2, 8))
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2) - 1,
    col = math.floor((vim.o.columns - width) / 2),
    border = "rounded",
    title = " " .. table.concat(title_parts, " ") .. " ",
    title_pos = "center",
  })
  vim.wo[win].wrap = false
  vim.wo[win].cursorline = true
  close_maps({ buf }, { win })
end

---Show the current file in a side-by-side vimdiff inside floating windows.
---@param base? string Revision to compare against. Defaults to HEAD.
function M.side_by_side(base)
  base = base or "HEAD"

  local root = git_root()
  if not root then
    return vim.notify("Not a git repository", vim.log.levels.WARN)
  end

  local rel = vim.fn.systemlist({
    "git",
    "-C",
    root,
    "ls-files",
    "--full-name",
    vim.fn.expand("%:p"),
  })[1]

  if not rel or rel == "" then
    return vim.notify("File is not tracked by git", vim.log.levels.WARN)
  end

  local old_lines = vim.fn.systemlist({ "git", "-C", root, "--no-pager", "show", base .. ":" .. rel })
  if vim.v.shell_error ~= 0 then
    return vim.notify("git show " .. base .. ":" .. rel .. " failed", vim.log.levels.ERROR)
  end

  local filetype = vim.bo.filetype
  local current_lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

  local total_width = math.min(vim.o.columns - 6, 220)
  local height = math.min(vim.o.lines - 6, 45)
  local pane_width = math.floor((total_width - 2) / 2)
  local row = math.floor((vim.o.lines - height) / 2) - 1
  local col = math.floor((vim.o.columns - total_width) / 2)

  local function open_pane(lines, column, title, modifiable)
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.bo[buf].filetype = filetype
    vim.bo[buf].bufhidden = "wipe"
    vim.bo[buf].modifiable = modifiable
    local win = vim.api.nvim_open_win(buf, false, {
      relative = "editor",
      width = pane_width,
      height = height,
      row = row,
      col = column,
      border = "rounded",
      title = title,
      title_pos = "center",
    })
    vim.wo[win].number = true
    vim.wo[win].foldcolumn = "0"
    return win, buf
  end

  local left_win, left_buf = open_pane(old_lines, col, (" %s:%s "):format(base, rel), false)
  local right_win, right_buf = open_pane(current_lines, col + pane_width + 2, " working tree ", true)

  for _, win in ipairs({ left_win, right_win }) do
    vim.api.nvim_win_call(win, function()
      vim.cmd("diffthis")
    end)
  end

  vim.api.nvim_set_current_win(right_win)
  close_maps({ left_buf, right_buf }, { left_win, right_win })
end

---Browse files changed against a base revision with a floating Telescope diff preview.
---@param base? string Base branch or revision. Defaults to origin/main.
function M.changed_vs_base(base)
  base = base or "origin/main"

  local root = git_root()
  if not root then
    return vim.notify("Not a git repository", vim.log.levels.WARN)
  end

  local range = diff_range(base)
  local files = vim.fn.systemlist({ "git", "-C", root, "diff", "--name-only", range })
  if vim.v.shell_error ~= 0 then
    return vim.notify("git diff failed:\n" .. table.concat(files, "\n"), vim.log.levels.ERROR)
  end
  if #files == 0 then
    return vim.notify("No changes vs " .. range, vim.log.levels.INFO)
  end

  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local previewers = require("telescope.previewers")
  local preview_utils = require("telescope.previewers.utils")

  pickers.new({
    prompt_title = "Changed vs " .. range,
    layout_strategy = "vertical",
    layout_config = {
      width = 0.9,
      height = 0.9,
      preview_height = 0.65,
    },
  }, {
    finder = finders.new_table({ results = files }),
    sorter = conf.generic_sorter({}),
    previewer = previewers.new_buffer_previewer({
      title = "Diff",
      define_preview = function(self, entry)
        local diff_lines = vim.fn.systemlist({
          "git",
          "-C",
          root,
          "--no-pager",
          "diff",
          "--no-color",
          range,
          "--",
          entry.value,
        })
        vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, diff_lines)
        preview_utils.highlighter(self.state.bufnr, "diff")
      end,
    }),
  }):find()
end

return M
