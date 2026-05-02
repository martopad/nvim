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

-- Package Management
vim.pack.add({
    { src = "https://github.com/mason-org/mason.nvim", name = "mason" },
    { src = "https://github.com/WhoIsSethDaniel/mason-tool-installer.nvim", name = "mason-tool-installer" }
})

-- LSP
vim.pack.add({
    { src = "https://github.com/mason-org/mason-lspconfig.nvim", name = "mason-lspconfig" },
    { src = "https://www.github.com/neovim/nvim-lspconfig", name = "nvim-lspconfig" },
    { src = "https://github.com/creativenull/efmls-configs-nvim", name = "efmls-configs" },
})
require("plugins/lsp")
require("plugins/lsp_keymaps")
require("plugins/lsps")

-- autocomplete
vim.pack.add({
    { src = "https://github.com/saghen/blink.cmp", name = "blink.cmp", version = vim.version.range("1.*")},
    { src = "https://github.com/L3MON4D3/LuaSnip", name = "luasnip" },
})
require("plugins/autocomplete_keymaps")
