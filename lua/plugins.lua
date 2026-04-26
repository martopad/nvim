-- ============================================================================
-- Contains stuff about plugins-- sources, and configuration.
-- It is configured this way to make sure that all "vim.pack.add" (imports)
-- are located in one place for easier maintenance.
-- ============================================================================

-- Theme
vim.pack.add({
    { src = "https://github.com/catppuccin/nvim", name = "catppuccin" },
})
require("plugins/colorscheme")

-- Status line
vim.pack.add({
    { src = "https://github.com/nvim-tree/nvim-web-devicons", name = "nvim-web-devicons" },
    { src = "https://github.com/nvim-lualine/lualine.nvim", name = "lualine" },
})
require("plugins/status_line")

-- Explorer View
vim.pack.add({
    { src = "https://github.com/nvim-tree/nvim-tree.lua", name = "nvim-tree.lua" },
    { src = "https://www.github.com/ibhagwan/fzf-lua", name = "fzf-lua"},
})
require("plugins/explorer_view")
require("plugins/explorer_view_keymaps")

-- QOL nvim lua functions
vim.pack.add({
    { src = "https://www.github.com/echasnovski/mini.nvim", name = "mini" },
})
require("plugins/mini")

-- Git integrations
vim.pack.add({
    { src = "https://www.github.com/lewis6991/gitsigns.nvim", name = "gitsigns.nvim" }
})
require("plugins/git_integrations")
require("plugins/git_integrations_keymaps")

-- Tree-sitter integrations
require("plugins/tree_sitter")
