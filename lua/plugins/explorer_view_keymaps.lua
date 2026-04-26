-- ============================================================================
-- To have an "explorer view" (directory tree) on the side. 
-- Keymap configuration: nvim-tree.lua
-- ============================================================================

vim.keymap.set("n", "<C-b>", function()
	require("nvim-tree.api").tree.toggle()
end, { desc = "Toggle NvimTree" })

vim.keymap.set("n", "<leader>b", function()
    require("nvim-tree.api").tree.open()
end, { desc = "Focus to NvimTree" })
