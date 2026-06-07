-- ============================================================================
-- Plugin Configuration: blink.cmp, LuaSnip
-- ============================================================================

return {
  {
    "saghen/blink.cmp",
    version = "1.*",
    dependencies = {
      {
        "L3MON4D3/LuaSnip",
        version = "v2.*",
        build = "make install_jsregexp",
      },
    },
    opts = {
      keymap = {
        preset = "none",
        ["<C-Space>"] = { "show", "hide" },
        ["<CR>"] = { "accept", "fallback" },
        ["<C-j>"] = { "select_next", "fallback" },
        ["<C-k>"] = { "select_prev", "fallback" },
        ["<Tab>"] = { "snippet_forward", "fallback" },
        ["<S-Tab>"] = { "snippet_backward", "fallback" },
      },
      appearance = {
        nerd_font_variant = "mono",
      },
      signature = {
        enabled = true,
      },
      sources = {
        default = { "lsp", "path", "buffer", "snippets" },
      },
      snippets = { preset = "luasnip" },
    },
    opts_extend = { "sources.default" },
  }
}
