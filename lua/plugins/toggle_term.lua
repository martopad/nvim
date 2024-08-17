return {
    {
        'akinsho/toggleterm.nvim',
        version = "*",
        config = function()
            require("toggleterm").setup{
                open_mapping = [[<c-\>]],
                autochdir = true,
                direction = horizontal
            }
        end
    }
}
