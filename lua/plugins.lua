-- ============================================================================
-- Contains stuff about plugins-- sources, and configuration.
-- ============================================================================

-- Theme
vim.pack.add({
    { src = "https://github.com/yorumicolors/yorumi.nvim", name = "yorumi" },
})
require("plugins/colorscheme")

-- Status line
vim.pack.add({
    { src = "https://github.com/nvim-tree/nvim-web-devicons", name = "nvim-web-devicons" },
    { src = "https://github.com/nvim-lualine/lualine.nvim", name = "lualine" },
})
require("plugins/status_line")
