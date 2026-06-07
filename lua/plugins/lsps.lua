-- ============================================================================
-- Plugin Configuration: Desired LSPs to be installed
--
-- efmls is a generic language server  that can be used to adapt linters and formatters
-- to act like language servers. So issues found by those tools are more
-- convenient to display.
-- ============================================================================

return {
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "williamboman/mason.nvim",
      "WhoIsSethDaniel/mason-tool-installer.nvim",
      "creativenull/efmls-configs-nvim" -- Ensures your efm requires work seamlessly
    },
    config = function()
      -- Add here: Non-Language Server Linter/Formatter
      local fmts_linters_non_ls = { "luacheck" }

      -- Add here: efmls imported configurations
      local languages = {
        python = {
          require("efmls-configs.formatters.ruff"),
          require("efmls-configs.formatters.ruff_sort"),
          require("efmls-configs.linters.ruff")
        },
        lua = {
          require("efmls-configs.linters.luacheck")
        }
      }

      -- Add here: Language servers and their configurations
      local lang_servers_and_configs = {
        { "basedpyright", {} },
        { "ruff",         {} },
        {
          "efm",
          {
            filetypes = vim.tbl_keys(languages),
            init_options = { documentFormatting = true },
            settings = {
              languages = languages
            }
          }
        },
        {
          "lua_ls",
          {
            -- lua_ls uses EmmyLuaCodeStyle(.editorconfig) configuration file format
            root_markers = { ".git", ".editorconfig", ".luarc.json" },
          }
        }
      }

      -- Mapping Neovim LSP IDs to Mason-specific names for installation
      -- There is no "lua_ls" package in Mason's registry. But "lua_ls" is still the name of
      -- the LSP to be used in neovim.
      local lsp_to_mason_map = {
        lua_ls = "lua-language-server",
      }

      local to_install = {}
      for _, entry in ipairs(lang_servers_and_configs) do
        local server_name = entry[1]
        -- Use the Mason translation fallback if it exists, otherwise use raw name
        local mason_package = lsp_to_mason_map[server_name] or server_name
        table.insert(to_install, mason_package)
      end

      -- Append non-ls tools to the install queue
      table.move(fmts_linters_non_ls, 1, #fmts_linters_non_ls, #to_install + 1, to_install)

      require("mason").setup()
      require("mason-tool-installer").setup({
        ensure_installed = to_install
      })

      -- Enable language servers natively via Neovim LSP IDs
      local lang_servers = vim.tbl_map(function(s)
        return s[1]
      end, lang_servers_and_configs)

      for _, entry in ipairs(lang_servers_and_configs) do
        local name = entry[1]
        local config = entry[2]

        vim.lsp.config(name, config)
      end
      vim.lsp.enable(lang_servers)
    end
  }
}
