-- ============================================================================
-- Plugin Configuration: Desired LSPs to be installed
--
-- efmls is a generic language server  that can be used to adapt linters and formatters
-- to act like language servers. So issues found by those tools are more
-- convenient to display.
-- ============================================================================

local fmt_ruff = require("efmls-configs.formatters.ruff")
local fmt_ruff_sort = require("efmls-configs.formatters.ruff_sort")
local lint_ruff = require("efmls-configs.linters.ruff")

local languages = {
    python = { fmt_ruff, fmt_ruff_sort, lint_ruff},
}

-- Append to this variable if you want to add more language servers.
local lang_servers_and_configs = {
    { "basedpyright", {} },
    { "ruff", {} },
    { "efm", {
            filetypes = vim.tbl_keys(languages),
            settings = {
                languages = languages,
            },
        },
    },
}

require("mason").setup()

local lang_servers = vim.tbl_map(function(s) return s[1] end, lang_servers_and_configs)
require("mason-lspconfig").setup({
  ensure_installed = lang_servers,
})

for _, entry in ipairs(lang_servers_and_configs) do
  local name = entry[1]
  local config = entry[2]

  vim.lsp.config(name, config)
  vim.lsp.enable(name)
end
