return {
    {
        'akinsho/toggleterm.nvim',
        version = "*",
        config = function()
            vim.keymap.set('t', '<C-w>', [[<C-\><C-n><C-w>]], opts)
            vim.keymap.set('t', '<esc>', [[<C-\><C-n>]], opts)
            vim.keymap.set('t', 'jk', [[<C-\><C-n>]], opts)
            vim.keymap.set('t', '<C-h>', [[<Cmd>wincmd h<CR>]], opts)
            vim.keymap.set('t', '<C-j>', [[<Cmd>wincmd j<CR>]], opts)
            vim.keymap.set('t', '<C-k>', [[<Cmd>wincmd k<CR>]], opts)
            vim.keymap.set('t', '<C-l>', [[<Cmd>wincmd l<CR>]], opts)
            require("toggleterm").setup{
                open_mapping = [[<c-\>]],
                autochdir = true,
                direction = horizontal,
                size = 20,
            }
        end
    }
}
