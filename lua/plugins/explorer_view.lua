-- ============================================================================
-- To have an "explorer view" (directory tree) on the side. 
-- Plugin configuration: nvim-tree.lua
-- ============================================================================

require("nvim-tree").setup({
	view = {
		width = 35,
	},
	filters = {
		dotfiles = false,
	},
	renderer = {
		group_empty = true,
	},
})
