-- ============================================================================
-- To have an "explorer view" (directory tree) on the side.
-- Plugin configuration: nvim-tree.lua, telescope
-- ============================================================================

return {
  {
    "nvim-tree/nvim-tree.lua",
    config = function(_, opts)
      -- This intercepts folders right on startup to cleanly execute the initialization path change
      if vim.fn.argc() > 0 then
        local target_path = vim.fn.argv(0)
        if vim.fn.isdirectory(target_path) == 1 then
          vim.cmd("cd " .. vim.fn.fnameescape(target_path))
        end
      end

      require("nvim-tree").setup(opts)
    end,
    keys = {
      {
        "<C-b>",
        function()
          require("nvim-tree.api").tree.toggle()
        end,
        desc = "Toggle NvimTree",
      },
      {
        "<leader>b",
        function()
          require("nvim-tree.api").tree.open()
        end,
        desc = "Focus to NvimTree",
      },
      {
        "<leader>bf",
        function()
          local current_file_path = vim.fn.expand("%:p")
          local real_file = vim.fn.filereadable(current_file_path) == 1
          if not real_file then
            return
          end
          require("nvim-tree.api").tree.open({ focus = true, find_file = true, path = current_file_path })
        end,
        desc = "Focus to NvimTree with respect to opened file",
      },
    },
    opts = {
      view = {
        width = 30,
      },
      filters = {
        dotfiles = false,
      },
      git = {
        ignore = false,
      },
      renderer = {
        group_empty = true,
      },
    },
  },
  {
    "nvim-telescope/telescope.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      require("telescope").setup({
        defaults = {
          mappings = {
            i = {
              ["<C-j>"] = require("telescope.actions").move_selection_next,
              ["<C-k>"] = require("telescope.actions").move_selection_previous,
            },
          },
        },
      })
    end,
    keys = {
      {
        "<leader>ff",
        function()
          vim.ui.input({
            prompt = "Find files in directory: ",
            default = vim.fn.getcwd() .. "/",
            completion = "dir"
          }, function(input)
            if input then
              require("telescope.builtin").find_files({ cwd = input })
            end
          end)
        end,
        desc = "Telescope find files in specified directory (cwd autocomplete)"
      },
      {
        "<leader>fg",
        function()
          vim.ui.input({
            prompt = "Live grep in directory: ",
            default = vim.fn.getcwd() .. "/",
            completion = "dir"
          }, function(input)
            if input then
              require("telescope.builtin").live_grep({ cwd = input })
            end
          end)
        end,
        desc = "Telescope live grep in specified directory (cwd autocomplete)"
      },
      {
        "<leader>fb",
        function()
          require("telescope.builtin").buffers()
        end,
        desc = "Telescope Buffers"
      },
      {
        "<leader>fc",
        function()
          require("telescope.builtin").commands()
        end,
        desc = "Telescope Commands"
      },
      {
        "<leader>fh",
        function()
          require("telescope.builtin").help_tags()
        end,
        desc = "Telescope Help Tags"
      },
      {
        "<leader>fx",
        function()
          require("telescope.builtin").diagnostics({ bufnr = 0 })
        end,
        desc = "Telescope Diagnostics Document"
      },
      {
        "<leader>fX",
        function()
          require("telescope.builtin").diagnostics()
        end,
        desc = "Telescope Diagnostics Workspace"
      },
      {
        "<leader>fp",
        function()
          local actions = require("telescope.actions")
          local action_state = require("telescope.actions.state")
          local builtin = require("telescope.builtin")

          builtin.find_files({
            attach_mappings = function(prompt_bufnr, map)
              actions.select_default:replace(function()
                local entry = action_state.get_selected_entry()
                actions.close(prompt_bufnr)

                local path = entry.path or entry.filename or entry.value
                vim.fn.setreg("+", path)
                print("Copied: " .. path)
              end)
              return true
            end,
          })
        end,
        desc = "Find file and copy path"
      },
    },
  },
}
