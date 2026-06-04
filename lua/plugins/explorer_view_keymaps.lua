-- ============================================================================
-- To have an "explorer view" (directory tree) on the side.
-- Keymap configuration: nvim-tree.lua, telescope
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

-- telescope
vim.keymap.set('n', '<leader>ff', function()
	vim.ui.input({
		prompt = 'Find files in directory: ',
		default = vim.fn.getcwd() .. '/',
		completion = 'dir'
	}, function(input)
		if input then
			require("telescope.builtin").find_files({ cwd = input })
		end
	end)
end, { desc = "Telescope find files in specified directory (cwd autocomplete)" })
vim.keymap.set('n', '<leader>fg', function()
	vim.ui.input({
		prompt = 'Live grep in directory: ',
		default = vim.fn.getcwd() .. '/',
		completion = 'dir'
	}, function(input)
		if input then
			require("telescope.builtin").live_grep({ cwd = input })
		end
	end)
end, { desc = "Telescope live grep in specified directory (cwd autocomplete)" })
vim.keymap.set("n", "<leader>fb", function()
	require("telescope.builtin").buffers()
end, { desc = "Telescope Buffers" })
vim.keymap.set("n", "<leader>fc", function()
	require("telescope.builtin").commands()
end, { desc = "Telescope Commands" })
vim.keymap.set("n", "<leader>fh", function()
	require("telescope.builtin").help_tags()
end, { desc = "Telescope Help Tags" })
vim.keymap.set("n", "<leader>fx", function()
	require("telescope.builtin").diagnostics({ bufnr = 0 })
end, { desc = "Telescope Diagnostics Document" })
vim.keymap.set("n", "<leader>fX", function()
	require("telescope.builtin").diagnostics()
end, { desc = "Telescope Diagnostics Workspace" })
vim.keymap.set("n", "<leader>fp", function()
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")
  local builtin = require("telescope.builtin")

  builtin.find_files({
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        local entry = action_state.get_selected_entry()
        actions.close(prompt_bufnr)

        local path = entry.path or entry.filename or entry.value
        vim.fn.setreg("+", path)
        print("Copied: " .. path)
      end)
      return true
    end,
  })
end, { desc = "Find file and copy path" })
