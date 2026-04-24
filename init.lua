-- ============================================================================
-- THEME
-- ============================================================================
vim.pack.add{{ src = "https://github.com/yorumicolors/yorumi.nvim", name = "yorumi" }}
vim.cmd.colorscheme("yorumi")

require("preferences_autocmds")
require("preferences_keymaps")
require("preferences_options")
