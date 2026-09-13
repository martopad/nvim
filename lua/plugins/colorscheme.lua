-- ============================================================================
-- Plugin Configuration: catppuccin
-- ============================================================================

return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    config = function()
      -- Configure the theme options here before loading it
      require("catppuccin").setup({
        flavour = "mocha",
        color_overrides = {
          all = {
            -- make text slightly darker than white.
            text = "#b8b8b8",
          },
          mocha = {
            -- make background black for OLED.
            base = "#000000",
          },
        },
        integrations = {
          -- Just use base catpuccin theme instead of applying catpuccin's nvimtree specific one.
          nvimtree = false,
          mini = {
            enabled = true,
            indentscope_color = "text",
          },
        },
      })
      -- Load the colorscheme
      vim.cmd([[colorscheme catppuccin]])
    end,
  }
}
