-- ============================================================================
-- Plugin Configuration: Desired LSPs to be installed
--
-- efmls is a generic language server  that can be used to adapt linters and formatters
-- to act like language servers. So issues found by those tools are more
-- convenient to display.
-- ============================================================================

-- Append to this variable if you have formatters or linters that will be used by efm.
local fmts_linters_non_ls = {
	"stylua",
	"luacheck",
}

-- Don't forget to sync the tools above with the neccessary efmls-configs below.
local fmt_ruff = require("efmls-configs.formatters.ruff")
local fmt_ruff_sort = require("efmls-configs.formatters.ruff_sort")
local fmt_stylua = require("efmls-configs.formatters.stylua")

local lint_ruff = require("efmls-configs.linters.ruff")
local lint_luacheck = require("efmls-configs.linters.luacheck")

local languages = {
	python = { fmt_ruff, fmt_ruff_sort, lint_ruff },
	lua = { lint_luacheck, fmt_stylua },
}

-- Append to this variable if you want to add more language servers.
local lang_servers_and_configs = {
	{ "basedpyright", {} },
	{ "ruff", {} },
	{
		"efm",
		{
			filetypes = vim.tbl_keys(languages),
			init_options = { documentFormatting = true },
			settings = {
				languages = languages,
			},
		},
	},
	{
		"lua_ls",
		{
			settings = {
				Lua = {
					diagnostics = { globals = { "vim" }, enable = true },
					telemetry = { enable = false },
				},
			},
		},
	},
}

local lang_servers = vim.tbl_map(function(s)
	return s[1]
end, lang_servers_and_configs)
local to_install = {}
-- copy lang_servers to to_install
table.move(lang_servers, 1, #lang_servers, 1, to_install)
-- copy fmts_linters_non_ls to to_install
table.move(fmts_linters_non_ls, 1, #fmts_linters_non_ls, #to_install + 1, to_install)

require("mason").setup()
require("mason-tool-installer").setup({
	ensure_installed = to_install,
	integrations = {
		["mason-lspconfig"] = true,
	},
})

for _, entry in ipairs(lang_servers_and_configs) do
	local name = entry[1]
	local config = entry[2]

	vim.lsp.config(name, config)
end

vim.lsp.enable(lang_servers)
