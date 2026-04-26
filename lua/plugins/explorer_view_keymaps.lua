-- ============================================================================
-- To have an "explorer view" (directory tree) on the side.
-- Keymap configuration: nvim-tree.lua, fzf-lua
-- ============================================================================

-- nvim-tree.lua
vim.keymap.set("n", "<C-b>", function()
	require("nvim-tree.api").tree.toggle()
end, { desc = "Toggle NvimTree" })
vim.keymap.set("n", "<leader>b", function()
    require("nvim-tree.api").tree.open()
end, { desc = "Focus to NvimTree" })

-- fzf-lua
vim.keymap.set("n", "<leader>ff", function()
	require("fzf-lua").files()
end, { desc = "FZF Files" })
vim.keymap.set("n", "<leader>fg", function()
	require("fzf-lua").live_grep()
end, { desc = "FZF Live Grep" })
vim.keymap.set("n", "<leader>fb", function()
	require("fzf-lua").buffers()
end, { desc = "FZF Buffers" })
vim.keymap.set("n", "<leader>fh", function()
	require("fzf-lua").help_tags()
end, { desc = "FZF Help Tags" })
vim.keymap.set("n", "<leader>fx", function()
	require("fzf-lua").diagnostics_document()
end, { desc = "FZF Diagnostics Document" })
vim.keymap.set("n", "<leader>fX", function()
	require("fzf-lua").diagnostics_workspace()
end, { desc = "FZF Diagnostics Workspace" })
