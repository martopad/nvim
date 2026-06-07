-- ============================================================================
-- Plugin Configuration: gitsigns
-- ============================================================================

return {
  {
    "lewis6991/gitsigns.nvim",
    keys = {
      {
        "]h",
        function()
          require("gitsigns").next_hunk()
        end,
        desc = "Next git hunk",
      },
      {
        "[h",
        function()
          require("gitsigns").prev_hunk()
        end,
        desc = "Previous git hunk",
      },
      {
        "<leader>hs",
        function()
          require("gitsigns").stage_hunk()
        end,
        desc = "Stage hunk",
      },
      {
        "<leader>hr",
        function()
          require("gitsigns").reset_hunk()
        end,
        desc = "Reset hunk",
      },
      {
        "<leader>hp",
        function()
          require("gitsigns").preview_hunk()
        end,
        desc = "Preview hunk",
      },
      {
        "<leader>hb",
        function()
          require("gitsigns").blame_line({ full = true })
        end,
        desc = "Blame line",
      },
      {
        "<leader>hB",
        function()
          require("gitsigns").toggle_current_line_blame()
        end,
        desc = "Toggle inline blame",
      },
      {
        "<leader>hd",
        function()
          require("gitsigns").diffthis()
        end,
        desc = "Diff this",
      },
    },
    opts = {
      signcolumn = true,
      current_line_blame = false,
    },
  }
}
