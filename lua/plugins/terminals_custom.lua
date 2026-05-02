-- ============================================================================
-- Custom terminal configuration. I want to have floating terminals that
-- retains size and position state during the current session.
-- Plugin configuration: toggleterm
-- ============================================================================

-- In‑memory state: lives only for the current session
local float_state = {
	row = nill,
	col = nill,
	width = nill,
	height = nill,
}

local function save_current_float_config(win)
	win = win or vim.api.nvim_get_current_win()
	local cfg = vim.api.nvim_win_get_config(win)

	if cfg.relative == "" then
		return -- not a floating window
	end

	local row = type(cfg.row) == "table" and cfg.row[false] or cfg.row
	local col = type(cfg.col) == "table" and cfg.col[false] or cfg.col

	float_state.row = row
	float_state.col = col
	float_state.width = cfg.width
	float_state.height = cfg.height
end

local function apply_saved_float_config(win)
	if not (float_state.row and float_state.col) then
		return
	end

	local cfg = vim.api.nvim_win_get_config(win)
	if cfg.relative == "" then
		return
	end

	cfg.row = float_state.row
	cfg.col = float_state.col
	cfg.width = float_state.width
	cfg.height = float_state.height

	vim.api.nvim_win_set_config(win, cfg)
end

local function move_current_float(dr, dc)
	local win = vim.api.nvim_get_current_win()
	local cfg = vim.api.nvim_win_get_config(win)

	-- Only act if this is a floating window
	if cfg.relative == "" then
		return
	end

	local a_row = type(cfg.row) == "table" and cfg.row[false] or cfg.row
	local a_col = type(cfg.col) == "table" and cfg.col[false] or cfg.col

	cfg.row = cfg.row + dr
	cfg.col = cfg.col + dc

	vim.api.nvim_win_set_config(win, cfg)
	save_current_float_config()
end

local function resize_current_float(dh, dw)
	local win = vim.api.nvim_get_current_win()
	local cfg = vim.api.nvim_win_get_config(win)

	-- Only act if this is a floating window
	if cfg.relative == "" then
		return
	end

	local new_height = math.max(1, cfg.height + dh)
	local new_width = math.max(1, cfg.width + dw)

	cfg.height = new_height
	cfg.width = new_width

	vim.api.nvim_win_set_config(win, cfg)
	save_current_float_config()
end

local default_size_pos = require("plugins.terminals_defaults")
local Terminal = require("toggleterm.terminal").Terminal
-- A single persistent floating terminal
local persistent_float = Terminal:new({
	display_name = "custom terminal",
	direction = "float",
	float_opts = {
		border = "curved",
		width = default_size_pos.width,
		height = default_size_pos.height,
		row = default_size_pos.row,
		col = default_size_pos.col,
	},
	on_open = function(term)
		vim.b[term.bufnr].my_term_name = "C"
		-- When the terminal opens: if we have saved geometry, apply it
		if term.window and vim.api.nvim_win_is_valid(term.window) then
			apply_saved_float_config(term.window)
			-- After applying, store whatever the final geometry is
			save_current_float_config(term.window)
		end
	end,
	on_close = function(term)
		-- Optionally capture again on close (if you moved/resized before closing)
		if term.window and vim.api.nvim_win_is_valid(term.window) then
			vim.api.nvim_set_current_win(term.window)
			save_current_float_config(term.window)
		end
	end,
})

-- Keymap to toggle this specific terminal
vim.keymap.set("n", "<leader>tt", function()
	persistent_float:toggle()
end, { noremap = true, silent = true })

function _G.set_custom_terminal_keymaps()
	local opts = { buffer = 0 }
	vim.keymap.set("t", "<C-a>", function()
		move_current_float(0, -3)
	end, opts)
	vim.keymap.set("t", "<C-d>", function()
		move_current_float(0, 3)
	end, opts)
	vim.keymap.set("t", "<C-s>", function()
		move_current_float(3, 0)
	end, opts)
	vim.keymap.set("t", "<C-w>", function()
		move_current_float(-3, 0)
	end, opts)

	vim.keymap.set("t", "<C-Left>", function()
		resize_current_float(0, -3)
	end, opts)
	vim.keymap.set("t", "<C-Right>", function()
		resize_current_float(0, 3)
	end, opts)
	vim.keymap.set("t", "<C-Down>", function()
		resize_current_float(3, 0)
	end, opts)
	vim.keymap.set("t", "<C-Up>", function()
		resize_current_float(-3, 0)
	end, opts)
end

-- Apply the custom keymap only for custom created terminals
vim.api.nvim_create_autocmd("TermEnter", {
	pattern = "term://*",
	callback = function(args)
		local bufnr = args.buf
		if vim.b[bufnr].my_term_name == "C" then
			vim.cmd("lua set_custom_terminal_keymaps()")
		end
	end,
})
