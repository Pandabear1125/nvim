# Neovim config

This config uses lazy.nvim with your previous Neovim config retrofitted into a categorized layout.

## Layout

- `init.lua`: entrypoint.
- `lua/config/lazy.lua`: lazy.nvim bootstrap/setup.
- `lua/core/`: Neovim-native settings, keymaps, terminal behavior, quickfix helpers, and autocommands.
- `lua/plugins/ui/`: theme, statusline, and diagnostics UI.
- `lua/plugins/editor/`: editor navigation/search plugins.
- `lua/plugins/lsp/`: LSP server and signature plugins.
- `lua/plugins/completion/`: completion, snippets, and completion icons.
- `lua/plugins/treesitter/`: Treesitter syntax support.
- `lua/plugins/git/`: Git integration.
- `lua/plugins/tools/`: Copilot and Markdown tooling.
