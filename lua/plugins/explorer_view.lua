-- ============================================================================
-- To have an "explorer view" (directory tree) on the side.
-- Plugin configuration: nvim-tree.lua, fzf-lua
-- ============================================================================

require("nvim-tree").setup({
	view = {
		width = 30,
	},
	filters = {
		dotfiles = false,
	},
	git = {
		ignore = false,
	},
	renderer = {
		group_empty = true,
	},
})

require("telescope").setup({
	defaults = {
		mappings = {
			i = {
				["<C-j>"] = require("telescope.actions").move_selection_next,
				["<C-k>"] = require("telescope.actions").move_selection_previous,
			},
		},
	},
})
