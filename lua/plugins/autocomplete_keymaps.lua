-- ============================================================================
-- Configuration for autocomplete capablities and keymaps.
-- Plugin Configuration: blink.cmp
-- ============================================================================

-- auto-build jsregexp C extension if missing
local function ensure_jsregexp_built()
    local luasnip_lua_path = vim.api.nvim_get_runtime_file("lua/luasnip/init.lua", false)[1]
    if not luasnip_lua_path then return end

    local luasnip_root = vim.fn.fnamemodify(luasnip_lua_path, ":h:h:h")
    local artifact = luasnip_root .. "/deps/jsregexp/jsregexp.so"

    if vim.fn.has("win32") == 1 then
        artifact = luasnip_root .. "/deps/jsregexp/jsregexp.dll"
    end

    if not vim.uv.fs_stat(artifact) then
        vim.notify("Building LuaSnip jsregexp in the background...", vim.log.levels.INFO)
        vim.system({ "make", "install_jsregexp" }, { cwd = luasnip_root }, function(out)
            vim.schedule(function()
                if out.code == 0 then
                    vim.notify("LuaSnip jsregexp built successfully!", vim.log.levels.INFO)
                else
                    vim.notify("Failed to build LuaSnip jsregexp:\n" .. (out.stderr or out.stdout or ""),
                        vim.log.levels.ERROR)
                end
            end)
        end)
    end
end
ensure_jsregexp_built()

require("blink.cmp").setup({
	keymap = {
		preset = "none",
		["<C-Space>"] = { "show", "hide" },
		["<CR>"] = { "accept", "fallback" },
		["<C-j>"] = { "select_next", "fallback" },
		["<C-k>"] = { "select_prev", "fallback" },
		["<Tab>"] = { "snippet_forward", "fallback" },
		["<S-Tab>"] = { "snippet_backward", "fallback" },
	},
	appearance = { nerd_font_variant = "mono" },
	completion = { menu = { auto_show = true } },
	sources = { default = { "lsp", "path", "buffer", "snippets" } },
	snippets = {
		expand = function(snippet)
			require("luasnip").lsp_expand(snippet)
		end,
	},

	fuzzy = {
		implementation = "prefer_rust",
		prebuilt_binaries = { download = true },
	},
})

vim.lsp.config["*"] = {
	capabilities = require("blink.cmp").get_lsp_capabilities(),
}
