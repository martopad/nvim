return {
    -- old config
    --[[
    {
        "williamboman/mason.nvim",
        config = function()
            require("mason").setup()
        end
    },
    {
        "williamboman/mason-lspconfig.nvim",
        config = function()
            require("mason-lspconfig").setup({
                ensure_installed = {
                    "lua_ls",
                    "basedpyright",
                    -- "rust_analyzer" -- system needs to have rust_analyzer, and rust-src installed
                }
            })
        end
    },
    ]]
    {
        "neovim/nvim-lspconfig",
        config = function()
            vim.lsp.enable({
                'basedpyright', -- this need basedpyright in system
                'lua_ls',
            })
            -- old config
            --[[ local capabilities = require("cmp_nvim_lsp").default_capabilities()
            vim.lsp.config('lua_ls', {
                capabilities = capabilities
            })
            vim.lsp.enable('basedpyright')
            vim.lsp.config('basedpyright', {
                capabilities = capabilities
            })
            -- can't get this to work. FFS
            vim.lsp.config("rust_analyzer", {
                settings = {
                    ["rust_analyzer"] = {
                        checkOnSave = true,
                        check = {
                            command = "clippy",
                            extraArgs = { "--no-deps" },
                        },
                    },
                },
            })
            ]]

            vim.keymap.set('n', 'K', vim.lsp.buf.hover, {})
            vim.keymap.set('n', 'gd', vim.lsp.buf.definition, {})
            vim.keymap.set({'n', 'v'}, '<leader>ca', vim.lsp.buf.code_action, {})
        end
    },
    {
        "mrcjkb/rustaceanvim",
        version = "^6", -- Recommended
        lazy = false, -- This plugin is already lazy
        config = function()
        vim.g.rust_recommended_style = false
            vim.g.rustaceanvim = {
                server = {
                },
                tools = {
                    enable_clippy = true,
                },
            }
            vim.keymap.set(
                "n",
                "K",
                function ()
                    vim.cmd.RustLsp({'hover', 'actions'})
                end,
                { silent = true, buffer = bufnr }
            )
        end,
   },
}
