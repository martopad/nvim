-- ============================================================================
-- Tree-sitter and Tree-sitter package management integrations
-- Plugin configuration: tree-sitter-manager
--
-- ============================================================================

require("tree-sitter-manager").setup({
    ensure_installed = { "markdown", "markdown_inline", "vim", "yaml" },
    border = "rounded",
    auto_install = true,
    highlight = true,
})
