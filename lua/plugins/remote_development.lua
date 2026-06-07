-- ============================================================================
-- Plugin Configuration: remote-nvim
-- Note: Needs wezterm.exe to be in PATH
-- ============================================================================

return {
  {
    "amitds1997/remote-nvim.nvim",
    version = "*",
    cmd = { "RemoteStart", "RemoteStop", "RemoteLog", "RemoteInfo", "RemoteCleanup", "RemoteConfigDel" },
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      "nvim-telescope/telescope.nvim",
    },
    init = function()
      if vim.env.SSH_TTY then
        -- Avoid requiring modules inside init. Use a callback function instead
        -- so Neovim defers loading the osc52 module until a clipboard action happens.
        vim.g.clipboard = {
          name = "OSC52",
          copy = {
            ["+"] = function(lines, regtype) require("vim.ui.clipboard.osc52").copy("+")(lines, regtype) end,
            ["*"] = function(lines, regtype) require("vim.ui.clipboard.osc52").copy("*")(lines, regtype) end,
          },
          paste = {
            ["+"] = function() return require("vim.ui.clipboard.osc52").paste("+")() end,
            ["*"] = function() return require("vim.ui.clipboard.osc52").paste("*")() end,
          },
        }
      end
    end,
    opts = {
      remote = {
        app_name = "nvim",
        copy_dirs = {
          config = {
            base = vim.fn.stdpath("config"),
            dirs = "*",
            compression = { enabled = true },
          },
        },
      },
      offline_mode = {
        enabled = true,
        no_github = false,
      },
      client_callback = function(port, workspace_config)
        local cmd

        -- Add if statements here if you want to handle different terminal emulators.
        -- I installed wezeterm on windows and it calls nvim in wsl. So the executables:
        -- On Windows: wezterm.exe, and wsl.exe
        -- Inside wsl: nvim
        local title = ("'Remote: %s'"):format(workspace_config.host)
        cmd = ("wezterm.exe cli set-tab-title --pane-id $(wezterm.exe cli spawn wsl.exe --exec nvim --server localhost:%s --remote-ui) %s")
            :format(port, title)

        vim.fn.jobstart(cmd, {
          detach = true,
          on_exit = function(job_id, exit_code, event_type)
            if exit_code ~= 0 then
              vim.notify(
                string.format("Remote client %d exited with error code %d", job_id, exit_code),
                vim.log.levels.ERROR
              )
            end
          end,
        })
      end,
    },
  },
}
