-- ============================================================================
-- Plugin Configuration: catppuccin
-- ============================================================================
--
require("catppuccin").setup {
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
    }
}

vim.cmd.colorscheme("catppuccin")
