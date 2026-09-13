-- ============================================================================
-- Plugin Configuration: tree-sitter-manager
-- ============================================================================

return {
  {
    "romus204/tree-sitter-manager.nvim",
    opts = {
      ensure_installed = { "markdown", "markdown_inline", "vim", "yaml" },
      border = "rounded",
      auto_install = true,
      highlight = true,
    },
  }
}
