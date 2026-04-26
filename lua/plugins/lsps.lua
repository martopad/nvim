-- ============================================================================
-- Plugin Configuration: Desired LSPs to be installed
-- ============================================================================

-- Append to this variable if you want to add more language servers.
local lang_servers_and_configs = {
  { "basedpyright", {} },
}

require("mason").setup()

local lang_servers = vim.tbl_map(function(s) return s[1] end, lang_servers_and_configs)
require("mason-lspconfig").setup({
  ensure_installed = lang_servers,
})

for _, entry in ipairs(lang_servers_and_configs) do
  local name = entry[1]
  local config = entry[2]

  vim.lsp.config(name, config)
  vim.lsp.enable(name)
end
