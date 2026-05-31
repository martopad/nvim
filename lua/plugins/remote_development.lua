-- ============================================================================
-- Remote Neovim development stuff.
-- Plugin configuration: remote-nvim
--
-- ============================================================================
--
-- Note: Needs wezterm.exe to be in PATH
require("remote-nvim").setup({
	remote = {
		app_name = "nvim", -- This directly maps to the value NVIM_APPNAME. If you use any other paths for configuration, also make sure to set this.
		-- List of directories that should be copied over
		copy_dirs = {
			-- What to copy to remote's Neovim config directory
			config = {
				base = vim.fn.stdpath("config"), -- Path from where data has to be copied
				dirs = "*",          -- Directories that should be copied over. "*" means all directories. To specify a subset, use a list like {"lazy", "mason"} where "lazy", "mason" are subdirectories
				-- under path specified in `base`.
				compression = {
					enabled = true, -- Should compression be enabled or not
				},
			},
			-- What to copy to remote's Neovim data directory
			-- data = {
			--     base = vim.fn.stdpath("data"),
			--     dirs = "*",
			--     compression = {
			--         enabled = true,
			--     },
			-- },
			-- -- What to copy to remote's Neovim cache directory
			-- cache = {
			--     base = vim.fn.stdpath("cache"),
			--     dirs = "*",
			--     compression = {
			--         enabled = true,
			--     },
			-- },
			-- -- What to copy to remote's Neovim state directory
			-- state = {
			--     base = vim.fn.stdpath("state"),
			--     dirs = "*",
			--     compression = {
			--         enabled = true,
			--     },
			-- },
		},
	},
	offline_mode = {
		enabled = true,
		no_github = false,
	},
	-- Callback on what to do after a remote connection is estblished:
	-- Spawn a wezterm tab so the new remote session is attached to that new tab.
	client_callback = function(port, workspace_config)
		local cmd = ("wezterm.exe cli set-tab-title --pane-id $(wezterm.exe cli spawn wsl.exe --exec nvim --server localhost:%s --remote-ui) %s")
			:format(
				port,
				("'Remote: %s'"):format(workspace_config.host)
			)
		if vim.env.TERM == "xterm-kitty" then
			cmd = ("kitty -e nvim --server localhost:%s --remote-ui"):format(port)
		end
		vim.fn.jobstart(cmd, {
			detach = true,
			on_exit = function(job_id, exit_code, event_type)
				-- This function will be called when the job exits
				print("Client", job_id, "exited with code", exit_code, "Event type:", event_type)
			end,
		})
	end,
})

-- Forward neovim copies from remote to client's clipboard.
if vim.env.SSH_TTY then
	local osc52 = require("vim.ui.clipboard.osc52")
	vim.g.clipboard = {
		name = "OSC52",
		copy = {
			["+"] = osc52.copy("+"),
			["*"] = osc52.copy("*"),
		},
		paste = {
			["+"] = osc52.paste("+"),
			["*"] = osc52.paste("*"),
		},
	}
end
