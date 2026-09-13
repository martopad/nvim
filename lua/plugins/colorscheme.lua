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

      -- Gerrit review comment overlays (git_floats side-by-side): a filled
      -- "card" panel with a colored left border, bold author, dim meta,
      -- readable body, and an Unresolved/Resolved footer badge.
      local card_bg = "#2b2a20"
      vim.api.nvim_set_hl(0, "GerritCommentBorder", { fg = "#c9a94a", bg = card_bg })
      vim.api.nvim_set_hl(0, "GerritCommentAuthor", { fg = "#f0e6c8", bg = card_bg, bold = true })
      vim.api.nvim_set_hl(0, "GerritCommentHeader", { fg = card_bg, bg = card_bg })
      vim.api.nvim_set_hl(0, "GerritCommentMeta", { fg = "#9d9878", bg = card_bg, italic = true })
      vim.api.nvim_set_hl(0, "GerritCommentBody", { fg = "#d7d0b8", bg = card_bg })
      vim.api.nvim_set_hl(0, "GerritCommentUnresolved", { fg = "#e88f5a", bg = card_bg, bold = true })
      vim.api.nvim_set_hl(0, "GerritCommentResolved", { fg = "#a3c98a", bg = card_bg })
      -- End-of-line marker on the commented code line (no card background).
      vim.api.nvim_set_hl(0, "GerritCommentSign", { fg = "#c9a94a" })
      vim.api.nvim_set_hl(0, "GerritCommentSignUnresolved", { fg = "#e88f5a", bold = true })
      -- Backwards-compatible alias.
      vim.api.nvim_set_hl(0, "GerritComment", { fg = "#f0e6c8", bg = card_bg, bold = true })
    end,
  },
}
