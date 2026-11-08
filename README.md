# Neovim config

My lightweight lazy neovim config.

## Layout

- `init.lua`: entrypoint.
- `lua/config/lazy.lua`: lazy.nvim bootstrap/setup.
- `lua/core/`: Neovim-native settings, filetype detection, keymaps, terminal behavior, quickfix helpers, and autocommands.
- `lua/plugins/init.lua`: imports every plugin category below.
- `lua/plugins/ui/`: theme, statusline, and diagnostics UI.
- `lua/plugins/editor/`: editor navigation/search plugins (Telescope, Oil).
- `lua/plugins/lsp/`: LSP server and signature plugins.
- `lua/plugins/completion/`: completion, snippets, and completion icons.
- `lua/plugins/treesitter/`: Treesitter syntax support.
- `lua/plugins/git/`: Git integration.
- `lua/plugins/tools/`: Copilot and Markdown tooling.
- `lua/objdump/`: objdump disassembly navigation (go-to-definition, hover, references, symbol picker, folding).
- `ftplugin/objdump.lua`: buffer-local objdump settings and keymaps.
- `syntax/objdump.vim`: objdump syntax highlighting.

## Keymaps

Leader is `<Space>`; localleader is `\`.

### Windows

| Mode | Key | Action |
| --- | --- | --- |
| n | `<C-h/j/k/l>` | Move to the window left/down/up/right |
| i | `<C-h>` | Delete the previous word |
| t | `<C-h/j/k/l>` | Leave terminal mode and move between windows |

### Registers and clipboard

| Mode | Key | Action |
| --- | --- | --- |
| n, x | `d` `D` `x` | Delete into the black hole register |
| n, x | `c` `C` | Change into the black hole register |
| n | `p` `P` | Paste from the system clipboard |
| x | `p` `P` | Paste over the selection without overwriting the clipboard |

On WSL, Neovim uses Windows' clipboard through `clip.exe` and `powershell.exe`.
Both commands must be available on WSL's `PATH` (Windows interoperability must
be enabled). macOS and other systems keep Neovim's default clipboard provider.
After updating the config, restart Neovim and check `:checkhealth vim.provider`
if clipboard access still fails.

### Editor tools

| Mode | Key | Action |
| --- | --- | --- |
| n | `=G` | clang-format the buffer (or `gg=G` when no `.clang-format`) |
| x | `<leader>rp` | Replace every literal occurrence of the selection in the current file |
| n | `<leader>lsp` | Restart LSP and Copilot |
| n | `<leader>mv` | Toggle Markdown preview (Markview) |
| n | `<C-S-j>` | Next quickfix item (centered, with flash) |
| n | `<C-S-k>` | Previous quickfix item (centered, with flash) |

Select text, press `<leader>rp`, and type its replacement in Telescope. `Enter`
replaces all case-sensitive matches, including occurrences inside longer words.
`Esc` cancels; an empty replacement deletes matches. One `u` undoes the entire
replacement. Changes stay in the buffer until you save.

### Terminal

| Mode | Key | Action |
| --- | --- | --- |
| n | `<leader>t` | Toggle the bottom terminal |
| n, t | `` <C-`> `` | Jump to the terminal or back to the last window |
| t | `<Esc>` | Leave terminal mode |

### Files and search

| Mode | Key | Action |
| --- | --- | --- |
| n | `<leader>ff` | Find files (Telescope) |
| n | `<leader>gf` | Grep files (Telescope) |
| n | `<leader>fs` | Search text (Telescope) |
| v | `<leader>gs` | Search the visual selection |
| n | `<leader>x` | Open the Oil file browser |
| n | `<leader>sp` | Open Oil in a vertical split |
| i, n | `<C-q>` | Telescope: send results to quickfix and open it |
| i, n | `<M-q>` | Telescope: add results to quickfix and open it |

In `<leader>ff`, `<leader>gf`, `<leader>fs`, and `<leader>gs`, type **two spaces**
in the Telescope prompt to separate the query from a file path filter:

- `telescope  lua/plugins/` finds matching files or text only under that path.
- `setup  *.lua` limits matches to Lua files.
- `  lua/core/` filters files or visual-selection matches without an extra query.

Path filters match literal path fragments or globs, relative to the search
directory. Everything stays inside Telescope and updates as you type. Visual
selection search starts in insert mode; the selected text stays the search term,
and text before the two spaces optionally refines its results.

### LSP (buffer-local, active when a server attaches)

| Mode | Key | Action |
| --- | --- | --- |
| n | `gd` | Go to definition |
| n | `gD` | Go to declaration |
| n | `gi` | Go to implementation |
| n | `gt` | Go to type definition |
| n | `gr` | List references |
| n | `K` | Hover documentation |
| n | `<leader>rn` | Rename symbol |
| n, v | `<leader>ca` | Code action |
| n, v | `<leader>f` | Format |
| n | `gl` | Show line diagnostics |
| n | `[d` / `]d` | Previous / next diagnostic |
| n | `<leader>q` | Send diagnostics to the location list |
| n | `<leader>wa` | Add workspace folder |
| n | `<leader>wr` | Remove workspace folder |
| n | `<leader>wl` | List workspace folders |

### Completion (nvim-cmp, insert mode)

| Mode | Key | Action |
| --- | --- | --- |
| i | `<C-Space>` | Trigger completion |
| i | `<S-Tab>` | Confirm the selected item |
| i | `<C-e>` | Abort completion |
| i | `<C-b>` / `<C-f>` | Scroll the documentation up / down |

### Copilot (insert mode)

| Mode | Key | Action |
| --- | --- | --- |
| i | `<D-l>` | Accept the next word |
| i | `<D-k>` | Accept the current line |
| i | `<D-j>` | Dismiss the suggestion |

### Objdump buffers (buffer-local)

| Mode | Key | Action |
| --- | --- | --- |
| n | `gd` | Go to definition |
| n | `K` | Hover symbol info |
| n | `gr` | List references |
| n | `<leader>ds` | Symbol picker (Telescope) |
