-- ============================================================================
-- Tree-sitter integrations.
-- Plugin configuration: built in nvim treesitter
--
-- Whenever you want to handle a new file format, you will need to
-- install the needed grammar lib and modify this lua file.
--
-- To check if nvim is able to parse the file:
-- 1. Open the file with nvim.
-- 2. Run ":InspecTree"
-- If OK: It will open a new split buffer showing the file's syntax tree.
-- If NOK: It will output "... no parser for lang "...""
-- ============================================================================

-- Installed via dev-libs/tree-sitter-python
vim.treesitter.language.add('python', { path = "/usr/lib64/libtree-sitter-python.so" })

-- Installed via dev-libs/tree-sitter-rust
vim.treesitter.language.add('rust', { path = "/usr/lib64/libtree-sitter-rust.so" })
