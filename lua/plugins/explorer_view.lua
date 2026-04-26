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
	renderer = {
		group_empty = true,
	},
})

require("fzf-lua").setup({})
