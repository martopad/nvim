-- ============================================================================
-- Plugin Configuration: gitsigns + floating git diff views
-- ============================================================================

local git_floats = function()
  return require("config.git_floats")
end

return {
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    keys = {
      {
        "]h",
        function()
          require("gitsigns").nav_hunk("next", { preview = true })
        end,
        desc = "Next git hunk (preview)",
      },
      {
        "[h",
        function()
          require("gitsigns").nav_hunk("prev", { preview = true })
        end,
        desc = "Previous git hunk (preview)",
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
        "<leader>hi",
        function()
          require("gitsigns").preview_hunk_inline()
        end,
        desc = "Preview hunk inline",
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
          git_floats().side_by_side("HEAD")
        end,
        desc = "Float side-by-side vs HEAD",
      },
      {
        "<leader>hgv",
        function()
          git_floats().side_by_side({ base = ":" })
        end,
        desc = "Float side-by-side unstaged (index)",
      },
      {
        "<leader>hgU",
        function()
          git_floats().review_side_by_side({ scope = "unstaged" })
        end,
        desc = "Review unstaged files (side-by-side)",
      },
      {
        "<leader>hgR",
        function()
          git_floats().review_side_by_side({ scope = "head" })
        end,
        desc = "Review all changes vs HEAD (side-by-side)",
      },
      {
        "<leader>hgC",
        function()
          git_floats().review_commit()
        end,
        desc = "Review commit (side-by-side)",
      },
      {
        "<leader>hgd",
        function()
          git_floats().unified()
        end,
        desc = "Float diff: file vs index",
      },
      {
        "<leader>hgD",
        function()
          git_floats().unified({ repo = true })
        end,
        desc = "Float diff: repository",
      },
      {
        "<leader>hgc",
        function()
          git_floats().unified({ staged = true })
        end,
        desc = "Float diff: staged",
      },
      {
        "<leader>hgm",
        function()
          git_floats().unified({ repo = true, base = "origin/main" })
        end,
        desc = "Float diff vs origin/main",
      },
      {
        "<leader>hgb",
        function()
          git_floats().changed_vs_base("origin/main")
        end,
        desc = "Browse changes vs origin/main",
      },
    },
    opts = {
      signcolumn = true,
      current_line_blame = false,
      preview_config = {
        border = "rounded",
        style = "minimal",
        relative = "cursor",
        row = 0,
        col = 1,
      },
    },
  },
}
