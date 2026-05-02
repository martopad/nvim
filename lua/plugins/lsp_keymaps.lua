-- ============================================================================
-- Setup General LSP behavior
-- Keymap configuration: nvim's builtin lsp integration
-- ============================================================================

-- based on https://github.com/radleylewis/nvim-lite/blob/master/init.lua
local function lsp_on_attach(ev)
	local client = vim.lsp.get_client_by_id(ev.data.client_id)
	if not client then
		return
	end

	local bufnr = ev.buf
	local opts = { noremap = true, silent = true, buffer = bufnr }

	vim.keymap.set("n", "<leader>gd", function()
		require("fzf-lua").lsp_definitions({ jump_to_single_result = true })
	end, opts)

	vim.keymap.set("n", "<leader>gD", vim.lsp.buf.definition, opts)

	vim.keymap.set("n", "<leader>gS", function()
		vim.cmd("vsplit")
		vim.lsp.buf.definition()
	end, opts)

	vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
	vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)

	vim.keymap.set("n", "<leader>D", function()
		vim.diagnostic.open_float({ scope = "line" })
	end, opts)
	vim.keymap.set("n", "<leader>d", function()
		vim.diagnostic.open_float({ scope = "cursor" })
	end, opts)
	vim.keymap.set("n", "<leader>nd", function()
		vim.diagnostic.jump({ count = 1 })
	end, opts)

	vim.keymap.set("n", "<leader>pd", function()
		vim.diagnostic.jump({ count = -1 })
	end, opts)

	vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)

	vim.keymap.set("n", "<leader>fd", function()
		require("fzf-lua").lsp_definitions({ jump_to_single_result = true })
	end, opts)
	vim.keymap.set("n", "<leader>fr", function()
		require("fzf-lua").lsp_references()
	end, opts)
	vim.keymap.set("n", "<leader>ft", function()
		require("fzf-lua").lsp_typedefs()
	end, opts)
	vim.keymap.set("n", "<leader>fs", function()
		require("fzf-lua").lsp_document_symbols()
	end, opts)
	vim.keymap.set("n", "<leader>fw", function()
		require("fzf-lua").lsp_workspace_symbols()
	end, opts)
	vim.keymap.set("n", "<leader>fi", function()
		require("fzf-lua").lsp_implementations()
	end, opts)

	vim.keymap.set("n", "<leader>fm", function()
		local ns_id = vim.api.nvim_create_namespace("lsp_format_highlight")

		-- 1. Snapshot the text before formatting
		local old_lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
		local old_text = table.concat(old_lines, "\n")

		-- 2. Execute formatting (must be sync to compare immediately)
		vim.lsp.buf.format({ bufnr = bufnr, async = false })

		-- 3. Snapshot the text after formatting
		local new_lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
		local new_text = table.concat(new_lines, "\n")
		-- 4. Use vim.diff to find changed hunks
		-- 'on_hunk' gives us: start_old, count_old, start_new, count_new
		vim.diff(old_text, new_text, {
			on_hunk = function(_, _, start_new, count_new)
				-- vim.hl.range is the high-level way to apply highlights to a range
				-- Arguments: bufnr, ns_id, hl_group, start_pos, end_pos, [opts]
				local row_start = start_new - 1
				local row_end = start_new + math.max(count_new, 1) - 1

				vim.hl.range(
					bufnr,
					ns_id,
					"Visual", -- This provides that subtle "yank" feel
					{ row_start, 0 },
					{ row_end, 0 },
					{
						inclusive = true,
						priority = 1000
					}
				)
			end
		})

		-- 5. Clear highlights after 200ms
		vim.defer_fn(function()
			if vim.api.nvim_buf_is_valid(bufnr) then
				vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)
			end
		end, 200)
		vim.notify(client.name .. " performed formatting on current buffer.")
	end, opts)
end

vim.api.nvim_create_autocmd("LspAttach", { group = augroup, callback = lsp_on_attach })

vim.keymap.set("n", "<leader>q", function()
	vim.diagnostic.setloclist({ open = true })
end, { desc = "Open diagnostic list" })
vim.keymap.set("n", "<leader>dl", vim.diagnostic.open_float, { desc = "Show line diagnostics" })
