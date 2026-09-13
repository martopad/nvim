-- Floating git diff views: unified patch text and side-by-side vimdiff panes.

local M = {}

local function resolve_toplevel(dir)
  if not dir or dir == "" then
    return nil
  end
  local out = vim.fn.systemlist({ "git", "-C", dir, "rev-parse", "--show-toplevel" })
  if vim.v.shell_error ~= 0 or not out[1] or out[1] == "" then
    return nil
  end
  return out[1]
end

---Resolve the git repo root. Neovim's cwd may not be the repo (e.g. the repo is
---a subdirectory of the opened workspace), so we probe, in order: an explicit
---path hint, the current buffer's directory, the `vim.g.git_floats_root`
---override, then the cwd. The first that resolves to a toplevel wins.
---@param path? string File or directory hint.
local function git_root(path)
  local candidates = {}
  if path and path ~= "" then
    table.insert(candidates, vim.fn.isdirectory(path) == 1 and path or vim.fn.fnamemodify(path, ":h"))
  end
  local file = vim.fn.expand("%:p")
  if file ~= "" then
    table.insert(candidates, vim.fn.fnamemodify(file, ":h"))
  end
  if vim.g.git_floats_root and vim.g.git_floats_root ~= "" then
    table.insert(candidates, vim.fn.expand(vim.g.git_floats_root))
  end
  table.insert(candidates, vim.fn.getcwd())

  for _, dir in ipairs(candidates) do
    local root = resolve_toplevel(dir)
    if root then
      return root
    end
  end
  return nil
end

local function diff_range(base)
  if base:find("%.%.", 1, true) then
    return base
  end
  return base .. "..."
end

local function match_editor_background(win)
  vim.wo[win].winhighlight = "Normal:Normal,NormalFloat:Normal"
end

---Configure a diff pane. Diff groups are remapped per-window to bg-only Gerrit
---groups so native diff supplies the line/word backgrounds (red left, green
---right) while Treesitter/syntax keeps the foreground colors on changed lines.
local function configure_diff_pane(win, side)
  vim.wo[win].list = false
  vim.wo[win].signcolumn = "no"
  vim.wo[win].foldcolumn = "0"
  vim.wo[win].wrap = false
  vim.wo[win].cursorline = false

  local line_hl = side == "right" and "GerritDiffAdd" or "GerritDiffDelete"
  local word_hl = side == "right" and "GerritDiffWord" or "GerritDiffWordDelete"
  vim.wo[win].winhighlight = table.concat({
    "Normal:Normal",
    "NormalFloat:Normal",
    "DiffAdd:" .. line_hl,
    "DiffChange:" .. line_hl,
    "DiffDelete:" .. line_hl,
    "DiffText:" .. word_hl,
    "DiffTextAdd:" .. word_hl,
    "DiffTextDelete:" .. word_hl,
  }, ",")
end

local function close_diff_windows(wins)
  for _, win in ipairs(wins) do
    if vim.api.nvim_win_is_valid(win) then
      pcall(vim.api.nvim_win_close, win, true)
    end
  end
end

local function close_maps(bufs, wins)
  local function close()
    close_diff_windows(wins)
    M._view = nil
    M._hidden = nil
  end

  for _, buf in ipairs(bufs) do
    vim.keymap.set("n", "q", close, { buffer = buf, nowait = true, desc = "Close diff" })
    vim.keymap.set("n", "<Esc>", close, { buffer = buf, nowait = true, desc = "Close diff" })
  end
end

---@class GitFloats.ReviewSession
---@field root string
---@field base string
---@field files string[] Relative paths.
---@field index integer
---@field kind? "working_tree"|"commit"|"gerrit"
---@field commit? string
---@field parent? string Parent revision for commit review. Nil for initial commits.
---@field comments? table<string, table[]> Gerrit comments keyed by file path.
---@field change? table Resolved Gerrit change info (number, subject, ...).

local function git_blob_lines(root, rev, rel)
  local ref = rev == ":" and (":" .. rel) or (rev .. ":" .. rel)
  local lines = vim.fn.systemlist({ "git", "-C", root, "--no-pager", "show", ref })
  if vim.v.shell_error ~= 0 then
    return {}
  end
  return lines
end

local function git_short_rev(root, rev)
  if rev == ":" then
    return "index"
  end
  return vim.fn.systemlist({ "git", "-C", root, "rev-parse", "--short", rev })[1] or rev
end

local function commit_parent(root, commit)
  local parent = vim.fn.systemlist({ "git", "-C", root, "rev-parse", "--verify", commit .. "^" })
  if vim.v.shell_error ~= 0 then
    return nil
  end
  return parent[1]
end

local function rev_exists(root, rev)
  vim.fn.system({ "git", "-C", root, "cat-file", "-e", rev .. "^{commit}" })
  return vim.v.shell_error == 0
end

local function fetch_gerrit_ref(root, ref)
  local out = vim.fn.systemlist({ "git", "-C", root, "fetch", "origin", ref })
  if vim.v.shell_error ~= 0 then
    return false, table.concat(out, "\n")
  end
  return true
end

local function commit_files(root, commit)
  local files = vim.fn.systemlist({
    "git",
    "-C",
    root,
    "diff-tree",
    "--no-commit-id",
    "--name-only",
    "-r",
    commit,
  })
  if vim.v.shell_error ~= 0 then
    return nil, "git diff-tree failed:\n" .. table.concat(files, "\n")
  end
  return files
end

local function file_nav_maps(session, wins, bufs)
  local function goto_file(delta)
    local next_index = session.index + delta
    if next_index < 1 or next_index > #session.files then
      return vim.notify("No more changed files", vim.log.levels.INFO)
    end
    close_diff_windows(wins)
    M.side_by_side({ session = vim.tbl_extend("force", session, { index = next_index }) })
  end

  for _, buf in ipairs(bufs) do
    vim.keymap.set("n", "]f", function()
      goto_file(1)
    end, { buffer = buf, desc = "Next changed file" })
    vim.keymap.set("n", "[f", function()
      goto_file(-1)
    end, { buffer = buf, desc = "Previous changed file" })
  end
end

---Sibling floats are not linked in the window tree, so wincmd h/l misses the other pane.
local function pane_maps(left_win, right_win, left_buf, right_buf)
  local function focus(win)
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_set_current_win(win)
    end
  end

  local function cycle()
    local cur = vim.api.nvim_get_current_win()
    if cur == left_win then
      focus(right_win)
    else
      focus(left_win)
    end
  end

  for _, buf in ipairs({ left_buf, right_buf }) do
    vim.keymap.set("n", "<C-h>", function()
      focus(left_win)
    end, { buffer = buf, desc = "Diff pane: left" })
    vim.keymap.set("n", "<C-l>", function()
      focus(right_win)
    end, { buffer = buf, desc = "Diff pane: right" })
    vim.keymap.set("n", "<Tab>", cycle, { buffer = buf, desc = "Cycle diff panes" })
    vim.keymap.set("n", "<C-w>w", cycle, { buffer = buf, desc = "Cycle diff panes" })
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
  match_editor_background(win)
  close_maps({ buf }, { win })
end

---@class GitFloats.SideBySideOpts
---@field base? string Revision to compare against. Defaults to HEAD. Use ":" for the index (unstaged).
---@field path? string Absolute file path. Defaults to the current buffer.
---@field session? GitFloats.ReviewSession Multi-file review session state.

---@class GitFloats.ReviewOpts
---@field scope? "unstaged"|"head"|"staged" Which changes to review. Default: unstaged.
---@field base? string Optional revision for file listing (e.g. origin/main).

local function changed_files(root, scope, base)
  local cmd = { "git", "-C", root, "diff", "--name-only" }
  if scope == "staged" then
    table.insert(cmd, "--cached")
  elseif scope == "head" then
    table.insert(cmd, "HEAD")
  elseif base then
    table.insert(cmd, diff_range(base))
  end
  local files = vim.fn.systemlist(cmd)
  if vim.v.shell_error ~= 0 then
    return nil, "git diff failed:\n" .. table.concat(files, "\n")
  end
  return files
end

local function first_commented_index(files, comments)
  if not comments then
    return nil
  end
  for index, file in ipairs(files) do
    local list = comments[file]
    if list and #list > 0 then
      return index
    end
  end
  return nil
end

local function review_index_for_current(files, root)
  local current = vim.fn.systemlist({
    "git",
    "-C",
    root,
    "ls-files",
    "--full-name",
    vim.fn.expand("%:p"),
  })[1]
  if not current then
    return 1
  end
  for index, file in ipairs(files) do
    if file == current then
      return index
    end
  end
  return 1
end

---Open a multi-file side-by-side review. Use ]f and [f to move between files.
---@param opts? GitFloats.ReviewOpts
function M.review_side_by_side(opts)
  opts = opts or {}
  local scope = opts.scope or "unstaged"

  local root = git_root()
  if not root then
    return vim.notify("Not a git repository", vim.log.levels.WARN)
  end

  local files, err = changed_files(root, scope, opts.base)
  if not files then
    return vim.notify(err, vim.log.levels.ERROR)
  end
  if #files == 0 then
    return vim.notify("No changed files to review", vim.log.levels.INFO)
  end

  local base = scope == "unstaged" and ":" or "HEAD"

  M.side_by_side({
    session = {
      root = root,
      base = base,
      kind = "working_tree",
      files = files,
      index = review_index_for_current(files, root),
    },
  })
end

---Open a side-by-side review of all files changed in a commit.
---@param commit? string Commit SHA. Opens a picker when omitted.
function M.review_commit(commit)
  local root = git_root()
  if not root then
    return vim.notify("Not a git repository", vim.log.levels.WARN)
  end

  local function start_review(sha)
    local files, err = commit_files(root, sha)
    if not files then
      return vim.notify(err, vim.log.levels.ERROR)
    end
    if #files == 0 then
      return vim.notify("Commit has no file changes", vim.log.levels.INFO)
    end

    M.side_by_side({
      session = {
        root = root,
        base = sha,
        kind = "commit",
        commit = sha,
        parent = commit_parent(root, sha),
        files = files,
        index = review_index_for_current(files, root),
      },
    })
  end

  if commit then
    return start_review(commit)
  end

  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")
  require("telescope.builtin").git_commits({
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        local entry = action_state.get_selected_entry()
        actions.close(prompt_bufnr)
        start_review(entry.value)
      end)
      return true
    end,
  })
end

---@class GitFloats.GerritOpts
---@field change? string|integer Change number or Change-Id. Defaults to HEAD's change.

---Review HEAD's Gerrit change side-by-side with reviewer comments overlaid.
---The right pane is the working tree (editable so you can address feedback).
---Falls back to a plain commit review when no Gerrit change is found.
---@param opts? GitFloats.GerritOpts
function M.review_gerrit(opts)
  opts = opts or {}

  local root = git_root()
  if not root then
    return vim.notify("Not a git repository", vim.log.levels.WARN)
  end

  vim.notify("Fetching Gerrit comments…", vim.log.levels.INFO)

  local gerrit = require("config.gerrit_comments")
  local info, err = gerrit.resolve_for_head(root, opts.change)
  if not info then
    vim.notify("Gerrit: " .. (err or "no change for HEAD") .. " — showing commit diff", vim.log.levels.WARN)
    return M.review_commit("HEAD")
  end

  local head = vim.fn.systemlist({ "git", "-C", root, "rev-parse", "HEAD" })[1]
  local target = info.revision_sha
  local session

  if target and target == head then
    -- Reviewing the checked-out change: diff its parent against the working
    -- tree so the right pane stays editable for addressing feedback.
    local files, ferr = commit_files(root, "HEAD")
    if not files then
      return vim.notify(ferr, vim.log.levels.ERROR)
    end
    if #files == 0 then
      return vim.notify("HEAD has no file changes", vim.log.levels.INFO)
    end
    session = {
      root = root,
      base = commit_parent(root, "HEAD") or "HEAD",
      kind = "gerrit",
      gerrit_revision_side = "right",
      files = files,
      index = first_commented_index(files, info.comments_by_path)
        or review_index_for_current(files, root),
      comments = info.comments_by_path,
      change = info,
    }
  else
    -- Reviewing some other change: make sure its patch set is present, then
    -- diff that revision against its parent (right pane read-only).
    if not target then
      return vim.notify("Gerrit change has no revision to review", vim.log.levels.ERROR)
    end
    if not rev_exists(root, target) then
      if not info.fetch_ref then
        vim.notify(
          string.format("Gerrit %s: patch set not local and no fetch ref (project %s?)", info.number, info.project or "?"),
          vim.log.levels.ERROR
        )
        return
      end
      vim.notify("Fetching Gerrit patch set " .. info.fetch_ref .. "…", vim.log.levels.INFO)
      local ok, ferr = fetch_gerrit_ref(root, info.fetch_ref)
      if not ok or not rev_exists(root, target) then
        vim.notify(
          string.format(
            "Gerrit %s: could not fetch %s (project %s).\n%s",
            info.number,
            info.fetch_ref,
            info.project or "?",
            ferr or ""
          ),
          vim.log.levels.ERROR
        )
        return
      end
    end

    local files, ferr = commit_files(root, target)
    if not files then
      return vim.notify(ferr, vim.log.levels.ERROR)
    end
    if #files == 0 then
      return vim.notify("Gerrit change has no file changes", vim.log.levels.INFO)
    end
    -- Compare the change's revision (left) against the local working tree
    -- (right, editable). No `commit` field => working-tree render.
    session = {
      root = root,
      base = target,
      kind = "gerrit",
      gerrit_revision_side = "left",
      files = files,
      index = first_commented_index(files, info.comments_by_path)
        or review_index_for_current(files, root),
      comments = info.comments_by_path,
      change = info,
    }
  end

  M.side_by_side({ session = session })

  local file_count, comment_count = 0, 0
  for _, list in pairs(info.comments_by_path or {}) do
    file_count = file_count + 1
    comment_count = comment_count + #list
  end

  vim.notify(
    string.format(
      "Gerrit %s PS%s: %s\n%d comment(s) across %d file(s)",
      info.number,
      info.target_ps or "?",
      info.subject or "",
      comment_count,
      file_count
    ),
    vim.log.levels.INFO
  )
end

---Show a file in a side-by-side vimdiff inside floating windows.
---@param opts? string|GitFloats.SideBySideOpts
function M.side_by_side(opts)
  if type(opts) == "string" then
    opts = { base = opts }
  end
  opts = opts or {}
  local base = opts.base or "HEAD"
  local session = opts.session
  -- A session already knows its repo; only re-detect for standalone opens
  -- (navigation/toggle can run while a scratch diff pane is focused).
  local root = (session and session.root) or git_root(opts.path)
  if not root then
    return vim.notify("Not a git repository", vim.log.levels.WARN)
  end

  -- A freshly opened view supersedes any previously hidden one.
  M._hidden = nil

  local path = opts.path or vim.fn.expand("%:p")
  local rel
  -- Commit-style rendering (parent vs revision, read-only right pane) applies
  -- to plain commit reviews and to Gerrit reviews of a non-checked-out change.
  local is_commit = session and session.commit ~= nil

  if session then
    rel = session.files[session.index]
    path = session.root .. "/" .. rel
    if not is_commit then
      base = session.base
    end
  end

  if path == "" then
    return vim.notify("No file to diff", vim.log.levels.WARN)
  end

  if not rel and not is_commit then
    rel = vim.fn.systemlist({
      "git",
      "-C",
      root,
      "ls-files",
      "--full-name",
      path,
    })[1]
  end

  if not rel or rel == "" then
    return vim.notify("File is not tracked by git", vim.log.levels.WARN)
  end

  if not is_commit and base == ":" then
    vim.fn.system({ "git", "-C", root, "diff", "--quiet", "--", rel })
    if vim.v.shell_error == 0 then
      return vim.notify("No unstaged changes in " .. rel, vim.log.levels.INFO)
    end
  end

  local old_lines
  local current_lines
  local left_label
  local right_label
  local right_modifiable = true

  if is_commit then
    left_label = session.parent and git_short_rev(root, session.parent) or "empty"
    right_label = git_short_rev(root, session.commit)
    old_lines = session.parent and git_blob_lines(root, session.parent, rel) or {}
    current_lines = git_blob_lines(root, session.commit, rel)
    right_modifiable = false
  else
    old_lines = git_blob_lines(root, base == ":" and ":" or base, rel)

    if opts.right_lines then
      current_lines = opts.right_lines
    elseif path == vim.fn.expand("%:p") then
      current_lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    else
      current_lines = vim.fn.readfile(path)
    end
    left_label = base == ":" and "index" or base
    right_label = "working tree"
    if session and session.kind == "gerrit" then
      if session.gerrit_revision_side == "left" then
        local ps = session.change and session.change.target_ps or "?"
        left_label = string.format("PS%s %s", ps, git_short_rev(root, base))
      else
        left_label = "base " .. git_short_rev(root, base)
      end
    end
  end

  local filetype = vim.bo.filetype
  if path ~= vim.fn.expand("%:p") then
    filetype = vim.filetype.match({ filename = path }) or ""
  end

  local file_title = session and string.format("[%d/%d] ", session.index, #session.files) or ""

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
    return win, buf
  end

  local left_win, left_buf = open_pane(
    old_lines,
    col,
    (" %s%s:%s "):format(file_title, left_label, rel),
    false
  )
  local right_win, right_buf = open_pane(
    current_lines,
    col + pane_width + 2,
    (" %s%s "):format(file_title, right_label),
    right_modifiable
  )

  configure_diff_pane(left_win, "left")
  configure_diff_pane(right_win, "right")

  for _, win in ipairs({ left_win, right_win }) do
    vim.api.nvim_win_call(win, function()
      vim.cmd("diffthis")
    end)
  end

  if session and session.kind == "gerrit" and session.comments then
    local gerrit = require("config.gerrit_comments")
    local file_comments = session.comments[rel]
    local rev_side = session.gerrit_revision_side or "right"
    local left_gside = rev_side == "left" and "REVISION" or "PARENT"
    local right_gside = rev_side == "right" and "REVISION" or "PARENT"
    gerrit.attach(left_buf, left_win, file_comments, left_gside)
    gerrit.attach(right_buf, right_win, file_comments, right_gside)
  end

  vim.api.nvim_set_current_win(right_win)
  pane_maps(left_win, right_win, left_buf, right_buf)
  if session then
    file_nav_maps(session, { left_win, right_win }, { left_buf, right_buf })
  end
  close_maps({ left_buf, right_buf }, { left_win, right_win })

  -- Remember this view so it can be hidden/restored (see M.toggle_diff_view).
  local reopen_opts = vim.tbl_extend("force", {}, opts)
  reopen_opts.right_lines = nil
  reopen_opts.path = path
  reopen_opts.base = base
  M._view = {
    left_win = left_win,
    right_win = right_win,
    left_buf = left_buf,
    right_buf = right_buf,
    right_modifiable = right_modifiable,
    reopen_opts = reopen_opts,
  }
end

---Hide the current side-by-side view, or restore the last hidden one.
---State (file, comments, cursor, and any right-pane edits) is preserved.
function M.toggle_diff_view()
  local v = M._view
  if v and (vim.api.nvim_win_is_valid(v.left_win) or vim.api.nvim_win_is_valid(v.right_win)) then
    local cur = vim.api.nvim_get_current_win()
    local focus_win = cur
    if not (cur == v.left_win or cur == v.right_win) then
      focus_win = vim.api.nvim_win_is_valid(v.right_win) and v.right_win or v.left_win
    end

    local saved = { side = "right" }
    if vim.api.nvim_win_is_valid(focus_win) then
      saved.cursor = vim.api.nvim_win_get_cursor(focus_win)
      saved.side = (focus_win == v.left_win) and "left" or "right"
    end

    local right_lines
    if v.right_modifiable and vim.api.nvim_buf_is_valid(v.right_buf) then
      right_lines = vim.api.nvim_buf_get_lines(v.right_buf, 0, -1, false)
    end

    close_diff_windows({ v.left_win, v.right_win })
    M._hidden = { reopen_opts = v.reopen_opts, right_lines = right_lines, saved = saved }
    M._view = nil
    return
  end

  if M._hidden then
    local h = M._hidden
    M._hidden = nil
    local opts = vim.tbl_extend("force", {}, h.reopen_opts or {})
    opts.right_lines = h.right_lines
    M.side_by_side(opts)

    local nv = M._view
    if nv and h.saved then
      local win = (h.saved.side == "left") and nv.left_win or nv.right_win
      local buf = (h.saved.side == "left") and nv.left_buf or nv.right_buf
      if win and vim.api.nvim_win_is_valid(win) then
        if h.saved.cursor and vim.api.nvim_buf_is_valid(buf) then
          local row = math.min(h.saved.cursor[1], vim.api.nvim_buf_line_count(buf))
          pcall(vim.api.nvim_win_set_cursor, win, { row, h.saved.cursor[2] })
        end
        vim.api.nvim_set_current_win(win)
      end
    end
    return
  end

  vim.notify("No side-by-side view to toggle", vim.log.levels.INFO)
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

---Start a multi-file unstaged side-by-side review at the first changed file.
function M.browse_unstaged()
  M.review_side_by_side({ scope = "unstaged" })
end

return M
