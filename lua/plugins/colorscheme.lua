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

      -- Gerrit-style line tints (bg only). GerritDiff* uses hl_mode=combine in git floats.
      local gerrit_diff = {
        add_line = "#1f3a28",
        add_word = "#2c553a",
        remove_line = "#320404",
        remove_word = "#62110f",
      }
      vim.api.nvim_set_hl(0, "GerritDiffAdd", { bg = gerrit_diff.add_line })
      vim.api.nvim_set_hl(0, "GerritDiffDelete", { bg = gerrit_diff.remove_line })
      vim.api.nvim_set_hl(0, "GerritDiffWord", { bg = gerrit_diff.add_word })
      vim.api.nvim_set_hl(0, "GerritDiffWordDelete", { bg = gerrit_diff.remove_word })

      -- Default vimdiff / unified-diff colors outside float panes.
      vim.api.nvim_set_hl(0, "DiffAdd", { bg = gerrit_diff.add_line })
      vim.api.nvim_set_hl(0, "DiffChange", { bg = gerrit_diff.add_line })
      vim.api.nvim_set_hl(0, "DiffDelete", { bg = gerrit_diff.remove_line })
      vim.api.nvim_set_hl(0, "DiffText", { bg = gerrit_diff.add_word })
      vim.api.nvim_set_hl(0, "DiffTextAdd", { bg = gerrit_diff.add_word })
      vim.api.nvim_set_hl(0, "DiffTextDelete", { bg = gerrit_diff.remove_word })
      vim.api.nvim_set_hl(0, "diffAdded", { bg = gerrit_diff.add_line })
      vim.api.nvim_set_hl(0, "diffRemoved", { bg = gerrit_diff.remove_line })
      vim.api.nvim_set_hl(0, "diffChanged", { bg = gerrit_diff.add_line })
    end,
  },
}
