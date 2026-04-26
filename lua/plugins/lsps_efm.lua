-- ============================================================================
-- Plugin Configuration: efmls
--
-- efmls is a generic language server  that can be used to adapt linters and formatters
-- to act like language servers. So issues found by those tools are more
-- convenient to display.
-- ============================================================================


require("mason-lspconfig").setup({
  ensure_installed = { "efm", "ruff" },
})

local fmt_ruff = require("efmls-configs.formatters.ruff")
local fmt_ruff_sort = require("efmls-configs.formatters.ruff_sort")
local lint_ruff = require("efmls-configs.linters.ruff")

local languages = {
    python = { fmt_ruff, fmt_ruff_sort, lint_ruff},
}

vim.lsp.config("efm", {
    filetypes = vim.tbl_keys(languages),
    settings = {
        languages = languages,
    },
})
