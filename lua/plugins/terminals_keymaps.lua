-- ============================================================================
-- Terminal integration and keymap configuration.
-- Plugin configuration: toggleterm
-- ============================================================================

local default_size_pos = require("plugins.terminals_defaults")

require("toggleterm").setup({
	open_mapping = [[<c-\>]],
	autochdir = true,
	direction = "horizontal",
	size = 20,
	persist_size = true,
	float_opts = {
		border = "curved",
		width = default_size_pos.width,
		height = default_size_pos.height,
		row = default_size_pos.row,
		col = default_size_pos.col,
	},
})

function _G.set_terminal_keymaps()
	local opts = { buffer = 0 }
	vim.keymap.set("t", "<esc>", [[<C-\><C-n>]], opts)
	vim.keymap.set("t", "jk", [[<C-\><C-n>]], opts)
	vim.keymap.set("t", "<C-h>", [[<Cmd>wincmd h<CR>]], opts)
	vim.keymap.set("t", "<C-j>", [[<Cmd>wincmd j<CR>]], opts)
	vim.keymap.set("t", "<C-k>", [[<Cmd>wincmd k<CR>]], opts)
	vim.keymap.set("t", "<C-l>", [[<Cmd>wincmd l<CR>]], opts)
	vim.keymap.set("t", "<C-w>", [[<C-\><C-n><C-w>]], opts)
end

-- Apply keymaps only to toggleterm created terminals.
vim.cmd("autocmd! TermOpen term://*toggleterm#* lua set_terminal_keymaps()")
