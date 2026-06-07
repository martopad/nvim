-- ============================================================================
-- Plugin Configuration: mini
-- Mini contains various quality of life improvements for nvim
-- ============================================================================

return {
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
