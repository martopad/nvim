-- Fetch Gerrit inline review comments for the HEAD commit (or an explicit
-- change) and overlay them onto the side-by-side diff panes in git_floats.
--
-- Auth/host can be configured via `vim.g.gerrit_review`, e.g.
--   vim.g.gerrit_review = {
--     base_url = "https://gerrit.ext.net.nokia.com",
--     path_prefix = "/a",        -- authenticated endpoints
--     curl_args = { "-n" },      -- --netrc (or use a cookie/header here)
--   }
-- If base_url is omitted it is derived from git config (gerrit.url / gerrit.host)
-- or the origin/gerrit remote URL.

local M = {}

local ns = vim.api.nvim_create_namespace("gerrit_comments")

---Per-buffer map of line number -> list of comments (for nav + float).
---@type table<integer, table<integer, table[]>>
local state = {}

local defaults = {
  base_url = nil,
  path_prefix = "/a",
  -- Many Gerrit installs live under a context path (e.g. .../gerrit or .../r).
  -- When base_url is derived from a remote we probe these until one answers.
  context_paths = { "", "/gerrit", "/r" },
  curl_args = { "-n" },
  strip_xssi = true,
  timeout_ms = 8000,
}

local function cfg()
  return vim.tbl_deep_extend("force", defaults, vim.g.gerrit_review or {})
end

-- ---------------------------------------------------------------------------
-- git helpers
-- ---------------------------------------------------------------------------

local function git_config(root, key)
  local out = vim.fn.systemlist({ "git", "-C", root, "config", "--get", key })
  if vim.v.shell_error ~= 0 or not out[1] or out[1] == "" then
    return nil
  end
  return out[1]
end

local function head_sha(root)
  local out = vim.fn.systemlist({ "git", "-C", root, "rev-parse", "HEAD" })
  if vim.v.shell_error ~= 0 then
    return nil
  end
  return out[1]
end

local function head_change_id(root)
  local msg = vim.fn.systemlist({ "git", "-C", root, "log", "-1", "--format=%B" })
  if vim.v.shell_error ~= 0 then
    return nil
  end
  for _, line in ipairs(msg) do
    local id = line:match("^Change%-Id:%s*(I%x+)")
    if id then
      return id
    end
  end
  return nil
end

-- ---------------------------------------------------------------------------
-- REST client
-- ---------------------------------------------------------------------------

local function derive_base_url(root)
  local c = cfg()
  if c.base_url then
    local url = c.base_url
    if not url:match("^https?://") then
      url = "https://" .. url
    end
    return (url:gsub("/+$", ""))
  end

  local explicit = git_config(root, "gerrit.url") or git_config(root, "gerrit.host")
  if explicit then
    if not explicit:match("^https?://") then
      explicit = "https://" .. explicit
    end
    return (explicit:gsub("/+$", ""))
  end

  for _, remote in ipairs({ "origin", "gerrit" }) do
    local url = git_config(root, "remote." .. remote .. ".url")
    if url then
      local host = url:match("^%w+://[^@]*@([^:/]+)")
        or url:match("^%w+://([^:/]+)")
        or url:match("^[^@/]+@([^:/]+):")
      if host then
        return "https://" .. host
      end
    end
  end

  return nil
end

local function urlencode(s)
  return (s:gsub("[^%w%-%._~]", function(ch)
    return string.format("%%%02X", string.byte(ch))
  end))
end

local STATUS_SENTINEL = "\n__GERRIT_HTTP_STATUS__"

---@return table|nil data, string|nil err
local function request(base, path)
  local c = cfg()
  local url = base .. path
  local args = {
    "curl",
    "-sS",
    "-L", -- follow redirects (login portals, /r prefixes, ...)
    "-H",
    "Accept: application/json",
    "-w",
    STATUS_SENTINEL .. "%{http_code}",
  }
  vim.list_extend(args, c.curl_args or {})
  table.insert(args, url)

  local ok, res = pcall(function()
    return vim.system(args, { text = true, timeout = c.timeout_ms }):wait()
  end)
  if not ok then
    return nil, "failed to run curl: " .. tostring(res)
  end
  if res.code ~= 0 then
    local detail = (res.stderr and res.stderr ~= "") and res.stderr or ("curl exit " .. res.code)
    return nil, detail .. "\nURL: " .. url
  end

  local body = res.stdout or ""
  local status = body:match(STATUS_SENTINEL:gsub("([^%w])", "%%%1") .. "(%d+)%s*$")
  body = body:gsub(STATUS_SENTINEL:gsub("([^%w])", "%%%1") .. "%d+%s*$", "")

  if status ~= "200" then
    local hint = ""
    if status == "401" or status == "403" then
      hint = " (auth failed — check curl_args / netrc / cookie)"
    elseif status == "404" then
      hint = " (wrong base URL or path_prefix?)"
    end
    local snippet = vim.trim(body):sub(1, 200)
    return nil, string.format("HTTP %s%s\nURL: %s\n%s", status or "?", hint, url, snippet)
  end

  if c.strip_xssi and body:sub(1, 4) == ")]}'" then
    body = body:gsub("^[^\n]*\n", "", 1)
  end

  local ok_json, parsed = pcall(vim.json.decode, body)
  if not ok_json then
    return nil, "invalid JSON from Gerrit: " .. tostring(parsed)
  end
  return parsed
end

-- ---------------------------------------------------------------------------
-- Change / comment resolution
-- ---------------------------------------------------------------------------

---Resolve the Gerrit change + comments for HEAD (or an explicit change id).
---@param root string
---@param change_override? string|integer Change number or Change-Id.
---@return table|nil info, string|nil err
function M.resolve_for_head(root, change_override)
  local base = derive_base_url(root)
  if not base then
    return nil, "could not determine Gerrit base URL (set vim.g.gerrit_review.base_url or gerrit.url)"
  end

  local c = cfg()
  local prefix = c.path_prefix or ""
  local sha = head_sha(root)
  if not sha then
    return nil, "could not resolve HEAD"
  end

  local query
  if change_override then
    query = "change:" .. tostring(change_override)
  else
    local change_id = head_change_id(root)
    query = change_id and ("change:" .. change_id) or ("commit:" .. sha)
  end

  -- If base_url is explicitly set we trust it; otherwise probe context paths.
  local candidates
  if c.base_url then
    candidates = { "" }
  else
    candidates = c.context_paths or { "" }
  end

  local changes, err, resolved_base
  for _, ctx in ipairs(candidates) do
    local try_base = base .. ctx
    local data, e = request(
      try_base,
      prefix .. "/changes/?q=" .. urlencode(query) .. "&o=ALL_REVISIONS"
    )
    if data then
      changes, resolved_base = data, try_base
      break
    end
    err = e
  end
  if not changes then
    return nil, err
  end
  base = resolved_base
  if type(changes) ~= "table" or not changes[1] then
    return nil, "no Gerrit change matched " .. query
  end

  local change = changes[1]
  local number = change._number
  if not number then
    return nil, "Gerrit change is missing a number"
  end

  -- Pick the revision to review: prefer the one matching local HEAD (so an
  -- in-progress checkout is reviewed against the working tree), else the
  -- change's current patch set, else the highest-numbered revision.
  local revs = change.revisions or {}
  local target_sha
  if revs[sha] then
    target_sha = sha
  elseif change.current_revision and revs[change.current_revision] then
    target_sha = change.current_revision
  else
    for rsha, rev in pairs(revs) do
      if not target_sha or (rev._number or 0) > ((revs[target_sha] or {})._number or 0) then
        target_sha = rsha
      end
    end
  end

  local target_ps, fetch_ref
  if target_sha and revs[target_sha] then
    target_ps = revs[target_sha]._number
    fetch_ref = revs[target_sha].ref
  end

  local comments, cerr = request(base, prefix .. "/changes/" .. number .. "/comments")
  if not comments then
    return nil, cerr
  end

  -- Keep comments from every patch set: reviewers often comment on an earlier
  -- revision, and filtering to a single PS tends to hide everything. The line
  -- headers show the patch set, so cross-PS context stays clear.
  local by_path = {}
  for path, list in pairs(comments) do
    if type(list) == "table" and #list > 0 then
      by_path[path] = list
    end
  end

  return {
    host = base,
    number = number,
    project = change.project,
    subject = change.subject,
    change_id = change.change_id,
    target_ps = target_ps,
    revision_sha = target_sha,
    fetch_ref = fetch_ref,
    comments_by_path = by_path,
  }
end

---Print diagnostics for the current repo's Gerrit resolution.
---@param root? string
---@param change_override? string|integer
function M.debug(root, change_override)
  root = root or vim.fn.getcwd()
  local base = derive_base_url(root)
  local c = cfg()
  local sha = head_sha(root)
  local cid = head_change_id(root)
  local lines = {
    "Gerrit debug",
    "  root:        " .. root,
    "  base_url:    " .. (base or "(none — set vim.g.gerrit_review.base_url)"),
    "  path_prefix: " .. tostring(c.path_prefix),
    "  curl_args:   " .. table.concat(c.curl_args or {}, " "),
    "  HEAD:        " .. (sha or "(none)"),
    "  Change-Id:   " .. (cid or "(none in commit message)"),
  }
  if base then
    local query
    if change_override then
      query = "change:" .. tostring(change_override)
    else
      query = cid and ("change:" .. cid) or ("commit:" .. tostring(sha))
    end
    local path = (c.path_prefix or "") .. "/changes/?q=" .. urlencode(query) .. "&o=ALL_REVISIONS"
    local candidates = c.base_url and { "" } or (c.context_paths or { "" })
    for _, ctx in ipairs(candidates) do
      local try_base = base .. ctx
      table.insert(lines, "  try URL:     " .. try_base .. path)
      local data, err = request(try_base, path)
      if data then
        table.insert(lines, "  result:      OK via " .. try_base .. " (" .. tostring(#data) .. " change(s))")
        break
      else
        for _, l in ipairs(vim.split(err or "", "\n", { plain = true })) do
          table.insert(lines, "      " .. l)
        end
      end
    end
  end
  vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO)
  return base
end

-- ---------------------------------------------------------------------------
-- Overlay rendering
-- ---------------------------------------------------------------------------

local function truncate(s, width)
  if width and width > 1 and vim.fn.strdisplaywidth(s) > width then
    return vim.fn.strcharpart(s, 0, width - 1) .. "…"
  end
  return s
end

---Word-wrap a (possibly multi-line) string to a display width.
---@param s string
---@param width integer
---@return string[]
local function wrap(s, width)
  width = math.max(1, width)
  local out = {}
  for _, para in ipairs(vim.split(s or "", "\n", { plain = true })) do
    if para == "" then
      table.insert(out, "")
    else
      local cur = ""
      for word in para:gmatch("%S+") do
        local candidate = cur == "" and word or (cur .. " " .. word)
        if vim.fn.strdisplaywidth(candidate) <= width then
          cur = candidate
        else
          if cur ~= "" then
            table.insert(out, cur)
            cur = ""
          end
          -- Hard-split a single word that is wider than the pane.
          while vim.fn.strdisplaywidth(word) > width do
            local part = vim.fn.strcharpart(word, 0, width)
            table.insert(out, part)
            word = vim.fn.strcharpart(word, vim.fn.strchars(part))
          end
          cur = word
        end
      end
      if cur ~= "" then
        table.insert(out, cur)
      end
    end
  end
  return out
end

local MONTHS = { "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec" }

---Format a Gerrit timestamp ("2026-08-05 09:19:06.000") as e.g. "Aug 05".
local function short_date(s)
  if not s then
    return ""
  end
  local _, mon, day = s:match("(%d+)-(%d+)-(%d+)")
  if not mon then
    return ""
  end
  return (MONTHS[tonumber(mon)] or mon) .. " " .. day
end

local function comment_line(comment)
  return comment.line or (comment.range and comment.range.start_line) or 0
end

---Group a file's comments for one pane by their target line.
---@param file_comments table[]|nil
---@param want "PARENT"|"REVISION" Which Gerrit comment side this pane shows.
local function collect(file_comments, want)
  local by_line = {}
  for _, comment in ipairs(file_comments or {}) do
    local cside = comment.side or "REVISION"
    if cside == want then
      local line = comment_line(comment)
      if line > 0 then
        by_line[line] = by_line[line] or {}
        table.insert(by_line[line], comment)
      end
    end
  end
  for _, list in pairs(by_line) do
    table.sort(list, function(a, b)
      return (a.updated or "") < (b.updated or "")
    end)
  end
  return by_line
end

local BORDER = "\u{258c}" -- ▌ left half block, drawn in the accent colour

---Build one card row: accent border + content padded to fill the card width.
local function card_row(text, hl, card_width)
  local pad = card_width - vim.fn.strdisplaywidth(text)
  if pad < 0 then
    pad = 0
  end
  return {
    { BORDER, "GerritCommentBorder" },
    { " " .. text .. string.rep(" ", pad) .. " ", hl },
  }
end

---Build the header row: bold author on the left, PS/date meta on the right.
local function header_row(comment, card_width)
  local author = (comment.author and comment.author.name) or "reviewer"
  local meta = string.format("PS%s \u{00b7} %s", comment.patch_set or "?", short_date(comment.updated))
  local gap = card_width - vim.fn.strdisplaywidth(author) - vim.fn.strdisplaywidth(meta)
  if gap < 1 then
    gap = 1
    author = truncate(author, card_width - vim.fn.strdisplaywidth(meta) - 1)
    gap = card_width - vim.fn.strdisplaywidth(author) - vim.fn.strdisplaywidth(meta)
    if gap < 1 then
      gap = 1
    end
  end
  return {
    { BORDER, "GerritCommentBorder" },
    { " " .. author, "GerritCommentAuthor" },
    { string.rep(" ", gap), "GerritCommentHeader" },
    { meta .. " ", "GerritCommentMeta" },
  }
end

local function render(buf, win, by_line)
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  -- virt_lines render in the text area, so exclude the number/sign/fold gutter
  -- (textoff) and the 3 columns the border + leading/trailing padding add.
  local info = vim.fn.getwininfo(win)[1]
  local textoff = (info and info.textoff) or 0
  local avail = math.max(24, vim.api.nvim_win_get_width(win) - textoff - 3)
  local card_width = math.min(avail, 96)
  local nlines = vim.api.nvim_buf_line_count(buf)

  for line, list in pairs(by_line) do
    if line <= nlines then
      local virt_lines = {}
      local unresolved = false

      for ci, comment in ipairs(list) do
        unresolved = unresolved or comment.unresolved == true

        -- top padding row
        table.insert(virt_lines, card_row("", "GerritCommentBody", card_width))
        -- author / meta header
        table.insert(virt_lines, header_row(comment, card_width))
        -- blank line under header
        table.insert(virt_lines, card_row("", "GerritCommentBody", card_width))
        -- wrapped body
        for _, msgline in ipairs(wrap(comment.message or "", card_width - 1)) do
          table.insert(virt_lines, card_row(msgline, "GerritCommentBody", card_width))
        end
        -- footer badge
        local status = comment.unresolved and "\u{25cf} Unresolved" or "\u{2713} Resolved"
        local status_hl = comment.unresolved and "GerritCommentUnresolved" or "GerritCommentResolved"
        table.insert(virt_lines, card_row("", "GerritCommentBody", card_width))
        table.insert(virt_lines, card_row(status, status_hl, card_width))
        -- bottom padding row
        table.insert(virt_lines, card_row("", "GerritCommentBody", card_width))

        -- gap between stacked cards (no card background)
        if ci < #list then
          table.insert(virt_lines, { { "", "Normal" } })
        end
      end

      vim.api.nvim_buf_set_extmark(buf, ns, line - 1, 0, {
        virt_lines = virt_lines,
        virt_lines_above = false,
      })
      vim.api.nvim_buf_set_extmark(buf, ns, line - 1, 0, {
        virt_text = {
          {
            " \u{1f4ac} " .. #list,
            unresolved and "GerritCommentSignUnresolved" or "GerritCommentSign",
          },
        },
        virt_text_pos = "eol",
      })
    end
  end
end

local function sorted_lines(by_line)
  local lines = vim.tbl_keys(by_line)
  table.sort(lines)
  return lines
end

---Open a float showing the full comment thread on the cursor line.
function M.show_float()
  local buf = vim.api.nvim_get_current_buf()
  local by_line = state[buf]
  if not by_line then
    return
  end
  local lnum = vim.api.nvim_win_get_cursor(0)[1]
  local list = by_line[lnum]
  if not list then
    return vim.notify("No Gerrit comment on this line", vim.log.levels.INFO)
  end

  local lines = {}
  local highlights = {}
  for i, comment in ipairs(list) do
    if i > 1 then
      table.insert(lines, "")
    end
    local author = (comment.author and comment.author.name) or "reviewer"
    local header = string.format(
      "%s (PS%s)%s",
      author,
      comment.patch_set or "?",
      comment.unresolved and "  [unresolved]" or ""
    )
    table.insert(lines, header)
    highlights[#lines] = comment.unresolved and "GerritCommentUnresolved" or "GerritComment"
    for _, msgline in ipairs(vim.split(comment.message or "", "\n", { plain = true })) do
      table.insert(lines, msgline)
    end
  end

  local fbuf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(fbuf, 0, -1, false, lines)
  vim.bo[fbuf].modifiable = false
  vim.bo[fbuf].bufhidden = "wipe"
  for lnr, hl in pairs(highlights) do
    vim.api.nvim_buf_add_highlight(fbuf, ns, hl, lnr - 1, 0, -1)
  end

  local width = 0
  for _, l in ipairs(lines) do
    width = math.max(width, vim.fn.strdisplaywidth(l))
  end
  width = math.min(math.max(width + 2, 30), math.floor(vim.o.columns * 0.6))

  local fwin = vim.api.nvim_open_win(fbuf, false, {
    relative = "cursor",
    width = width,
    height = math.min(#lines, 20),
    row = 1,
    col = 0,
    border = "rounded",
    title = " Gerrit comment ",
    title_pos = "center",
    style = "minimal",
  })
  vim.wo[fwin].wrap = true
  vim.keymap.set("n", "q", function()
    if vim.api.nvim_win_is_valid(fwin) then
      vim.api.nvim_win_close(fwin, true)
    end
  end, { buffer = fbuf, nowait = true })
  vim.api.nvim_create_autocmd("CursorMoved", {
    once = true,
    callback = function()
      if vim.api.nvim_win_is_valid(fwin) then
        vim.api.nvim_win_close(fwin, true)
      end
    end,
  })
end

local function set_maps(buf)
  local function jump(delta)
    local by_line = state[buf]
    if not by_line then
      return
    end
    local lines = sorted_lines(by_line)
    if #lines == 0 then
      return
    end
    local cur = vim.api.nvim_win_get_cursor(0)[1]
    local target
    if delta > 0 then
      for _, l in ipairs(lines) do
        if l > cur then
          target = l
          break
        end
      end
      target = target or lines[1]
    else
      for i = #lines, 1, -1 do
        if lines[i] < cur then
          target = lines[i]
          break
        end
      end
      target = target or lines[#lines]
    end
    vim.api.nvim_win_set_cursor(0, { target, 0 })
  end

  vim.keymap.set("n", "]r", function()
    jump(1)
  end, { buffer = buf, desc = "Next review comment" })
  vim.keymap.set("n", "[r", function()
    jump(-1)
  end, { buffer = buf, desc = "Previous review comment" })
  vim.keymap.set("n", "K", M.show_float, { buffer = buf, desc = "Show review comment" })
  vim.keymap.set("n", "<leader>hc", M.show_float, { buffer = buf, desc = "Show review comment" })
end

---Render comments for one pane and wire up navigation/float keymaps.
---@param buf integer
---@param win integer
---@param file_comments table[]|nil Comments for this file (all sides).
---@param gerrit_side "PARENT"|"REVISION" Which comment side this pane shows.
function M.attach(buf, win, file_comments, gerrit_side)
  local by_line = collect(file_comments, gerrit_side)
  state[buf] = by_line
  render(buf, win, by_line)
  set_maps(buf)
  vim.api.nvim_create_autocmd("BufWipeout", {
    buffer = buf,
    once = true,
    callback = function()
      state[buf] = nil
    end,
  })
end

return M
