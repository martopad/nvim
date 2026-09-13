-- ============================================================================
-- Plugin Configuration: moonfly
-- ============================================================================

return {
  {
    "bluz71/vim-moonfly-colors",
    name = "moonfly",
    lazy = false,
    priority = 1000,
    config = function()
      vim.g.moonflyItalics = true
      vim.g.moonflyUnderlineMatchParen = true
      vim.g.moonflyNormalFloat = true
      require("moonfly").custom_colors({
        bg = "#000000",
        black = "#000000",
      })
      vim.cmd.colorscheme("moonfly")

  },
}
