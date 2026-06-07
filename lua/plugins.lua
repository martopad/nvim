-- ============================================================================
-- Contains stuff about plugins-- sources, and configuration.
-- It is configured this way to make sure that all "vim.pack.add" (imports)
-- are located in one place for easier maintenance.
-- ============================================================================




-- Git integrations
vim.pack.add({
	{ src = "https://www.github.com/lewis6991/gitsigns.nvim", name = "gitsigns.nvim" },
})
require("plugins/git_integrations")
require("plugins/git_integrations_keymaps")

-- Tree-sitter and Tree-sitter package management integrations
vim.pack.add {
	{ src = "https://github.com/romus204/tree-sitter-manager.nvim", name = "tree-sitter-manager" }
}
require("plugins/tree_sitter")

-- autocomplete
vim.pack.add({
	{ src = "https://github.com/saghen/blink.cmp", name = "blink.cmp", version = vim.version.range("1.*") },
	{ src = "https://github.com/L3MON4D3/LuaSnip", name = "luasnip" },
})
require("plugins/autocomplete_keymaps")

-- Terminals
vim.pack.add({
	{ src = "https://github.com/akinsho/toggleterm.nvim", name = "toggleterm" },
})
require("plugins/terminals_keymaps")
require("plugins/terminals_custom")

-- Remote Development
vim.pack.add({
	{ src = "https://www.github.com/nvim-lua/plenary.nvim",   name = "plenary" },
	{ src = "https://github.com/amitds1997/remote-nvim.nvim", name = "remote-nvim" },
	{ src = "https://github.com/MunifTanjim/nui.nvim",        name = "nui" },
})
require("plugins/remote_development")
