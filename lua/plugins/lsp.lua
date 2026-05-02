-- ============================================================================
-- Plugin Configuration: Language Servers
-- ============================================================================

-- based on https://github.com/radleylewis/nvim-lite/blob/master/init.lua
-- Show LSP errors as vim diagnostics. Without it, issues found wont be shown in the editor.
local diagnostic_signs = {
	Error = " ",
	Warn = " ",
	Hint = "",
	Info = "",
}

vim.diagnostic.config({
	-- virtual_text = { prefix = "●", spacing = 4 },
	-- I commented the above line in favor of the bottom one, and to remind my future self.
	-- Before: Show issues count as "●" and text of the first issue on the line.
	-- ```
	-- some_code(with, issues)  ●● "problem foo found on this line"
	-- ```
	-- Now: Only show issues as ● indicate to the user that there is/are issue/s on a line.
	-- ```
	-- some_code(with, issues)  ●●
	-- ```
	-- Why: To stop cluttering the file with diagnostics. There are shortcuts if the user
	--      wants to actually look at what the issues are.
	virtual_text = {
		format = function(diagnostic)
			return ""
		end,
		prefix = "●",
	},
	signs = {
		text = {
			[vim.diagnostic.severity.ERROR] = diagnostic_signs.Error,
			[vim.diagnostic.severity.WARN] = diagnostic_signs.Warn,
			[vim.diagnostic.severity.INFO] = diagnostic_signs.Info,
			[vim.diagnostic.severity.HINT] = diagnostic_signs.Hint,
		},
	},
	underline = true,
	update_in_insert = false,
	severity_sort = true,
	float = {
		border = "rounded",
		source = "always",
		header = "",
		prefix = "",
		focusable = false,
		style = "minimal",
	},
})

do
	local orig = vim.lsp.util.open_floating_preview
	function vim.lsp.util.open_floating_preview(contents, syntax, opts, ...)
		opts = opts or {}
		opts.border = opts.border or "rounded"
		return orig(contents, syntax, opts, ...)
	end
end
