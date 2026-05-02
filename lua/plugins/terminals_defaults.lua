-- ============================================================================
-- Default configuration for terminal stuff.
-- ============================================================================

-- current editor size
local columns = vim.o.columns
local lines = vim.o.lines

local width = math.floor(columns * 0.75)
local height = math.floor(lines * 0.75)

local terminal_default_size_pos = {
	width = width,
	height = height,
	col = math.floor((columns - width) * 0.5),
	row = math.floor((lines - height) * 0.65),
}

return terminal_default_size_pos
