-- ============================================================================
-- Plugin Configuration: toggleterm
-- ============================================================================

return {
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    keys = {
      {
        [[<c-\>]],
        desc = "Toggle terminal",
      },
      {
        "<leader>tt",
        function()
          require("config.terminals_custom")
        end,
        desc = "Toggle custom float terminal",
      },
    },
    opts = function()
      local d = require("config.terminals_defaults")

      return {
        open_mapping = [[<c-\>]],
        autochdir = true,
        direction = "horizontal",
        size = 20,
        persist_size = true,
        float_opts = {
          border = "curved",
          width = d.width,
          height = d.height,
          row = d.row,
          col = d.col,
        },
      }
    end,
    config = function(_, opts)
      require("toggleterm").setup(opts)

      vim.api.nvim_create_autocmd("TermOpen", {
        pattern = "term://*toggleterm#*",
        callback = function()
          local bufopts = { buffer = 0 }
          vim.keymap.set("t", "<esc>", [[<C-\><C-n>]], bufopts)
          vim.keymap.set("t", "jk", [[<C-\><C-n>]], bufopts)
          vim.keymap.set("t", "<C-h>", [[<Cmd>wincmd h<CR>]], bufopts)
          vim.keymap.set("t", "<C-j>", [[<Cmd>wincmd j<CR>]], bufopts)
          vim.keymap.set("t", "<C-k>", [[<Cmd>wincmd k<CR>]], bufopts)
          vim.keymap.set("t", "<C-l>", [[<Cmd>wincmd l<CR>]], bufopts)
          vim.keymap.set("t", "<C-w>", [[<C-\><C-n><C-w>]], bufopts)
        end,
      })
    end,
  },
}
