-- ============================================================================
-- Various small packages that don't fit into any other category, but are still useful to have.
-- Plugin Configuration: mini
-- ============================================================================

return {
  {
    "sphamba/smear-cursor.nvim",
    opts = {},
  },
  {
    "echasnovski/mini.nvim",
    config = function()
      require("mini.comment").setup()
      require("mini.surround").setup()
      require("mini.indentscope").setup()
      require("mini.trailspace").setup()
      require("mini.bufremove").setup()
      require("mini.notify").setup()
    end,
  },
}
