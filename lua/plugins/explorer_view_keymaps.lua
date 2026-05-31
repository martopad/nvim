-- ============================================================================
-- To have an "explorer view" (directory tree) on the side.
-- Keymap configuration: nvim-tree.lua, fzf-lua
-- ============================================================================

local function open_nvim_tree(data)
	-- buffer is a real file on the disk
	local real_file = vim.fn.filereadable(data.file) == 1

	if not real_file then
		return
	end

	require("nvim-tree.api").tree.open({ focus = true, find_file = true, path = data.file })
end

-- nvim-tree.lua
vim.keymap.set("n", "<C-b>", function()
	require("nvim-tree.api").tree.toggle()
end, { desc = "Toggle NvimTree" })
vim.keymap.set("n", "<leader>b", function()
	require("nvim-tree.api").tree.open()
end, { desc = "Focus to NvimTree" })
vim.keymap.set("n", "<leader>bf", function()
	-- Get the full path of the current buffer's file
	local current_file_path = vim.fn.expand('%:p')

	open_nvim_tree({ file = current_file_path })
end, { desc = "Focus to NvimTree with respect to opened file" })

-- fzf-lua
vim.keymap.set('n', '<leader>ff', function()
	vim.ui.input({
		prompt = 'FZF files in directory: ',
		default = vim.fn.getcwd() .. '/',
		completion = 'dir'
	}, function(input)
		-- If the user didn't cancel (input is nil if Esc is pressed)
		if input then
			require("fzf-lua").files({ cwd = input })
		end
	end)
end, { desc = "Fzf files in specified directory (cwd autocomple)" })
vim.keymap.set('n', '<leader>fg', function()
	vim.ui.input({
		prompt = 'Live grep in directory:',
		default = vim.fn.getcwd() .. '/',
		completion = 'dir'
	}, function(input)
		-- If the user didn't cancel (input is nil if Esc is pressed)
		if input then
			require("fzf-lua").live_grep({ cwd = input })
		end
	end)
end, { desc = "Fzf files in specified directory (cwd autocomple)" })
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
