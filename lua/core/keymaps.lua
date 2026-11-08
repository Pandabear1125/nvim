local opts = { noremap = true, silent = true }
local quickfix_flash_ns = vim.api.nvim_create_namespace("QuickfixJumpFlash")
local quickfix_flash_ms = 250

-- Restart active LSP clients when the command exists.
local function restart_lsp()
  if vim.fn.exists(":LspRestart") == 2 then
    vim.cmd("LspRestart")
  end
end

-- Check whether the current project root has a clang-format config.
local function has_clang_format_file()
  return vim.uv.fs_stat(vim.fn.getcwd() .. "/.clang-format") ~= nil
end

-- Format with clang-format when configured, otherwise use Vim indentation.
local function clang_or_indent()
  if has_clang_format_file() then
    vim.cmd("%!clang-format")
  else
    vim.cmd("normal! gg=G")
  end
end

-- Ask Copilot to restart after other editor commands have settled.
local function restart_copilot()
  if vim.fn.exists(":Copilot") == 2 then
    pcall(vim.cmd, "Copilot restart")
  end
end

-- Restart both LSP and Copilot for a clean language tooling refresh.
local function restart_lsp_and_copilot()
  restart_lsp()
  vim.defer_fn(restart_copilot, 300)
end

-- Toggle Markview when it is installed, otherwise report that it is missing.
local function toggle_markview()
  if vim.fn.exists(":Markview") == 2 then
    vim.cmd("Markview Toggle")
  else
    vim.notify("Markview plugin not found", vim.log.levels.WARN)
  end
end

-- Briefly highlight the current line after a quickfix jump.
local function flash_quickfix_line()
  local bufnr = vim.api.nvim_get_current_buf()
  local line = vim.api.nvim_win_get_cursor(0)[1] - 1

  vim.api.nvim_buf_clear_namespace(bufnr, quickfix_flash_ns, 0, -1)
  vim.api.nvim_buf_set_extmark(bufnr, quickfix_flash_ns, line, 0, {
    line_hl_group = "IncSearch",
    hl_eol = true,
  })

  vim.defer_fn(function()
    if vim.api.nvim_buf_is_valid(bufnr) then
      vim.api.nvim_buf_clear_namespace(bufnr, quickfix_flash_ns, 0, -1)
    end
  end, quickfix_flash_ms)
end

-- Run a quickfix jump command, center the target, and flash the landed line.
local function jump_quickfix(command, failure_message)
  local ok = pcall(vim.cmd, command)
  if ok then
    vim.cmd("normal! zz")
    flash_quickfix_line()
  else
    vim.notify(failure_message, vim.log.levels.WARN)
  end
end

-- Jump to the next quickfix entry and center the target line.
local function next_quickfix_item()
  jump_quickfix("cnext", "No next quickfix item")
end

-- Jump to the previous quickfix entry and center the target line.
local function previous_quickfix_item()
  jump_quickfix("cprevious", "No previous quickfix item")
end

vim.keymap.set("n", "=G", clang_or_indent, { desc = "Clang format or normal indent" })
vim.keymap.set("x", "<leader>rp", function()
  require("core.replace").visual()
end, { desc = "Replace selection throughout current file" })

-- Window navigation with Ctrl + hjkl
vim.keymap.set("n", "<C-h>", "<C-w>h", opts)
vim.keymap.set("n", "<C-j>", "<C-w>j", opts)
vim.keymap.set("n", "<C-k>", "<C-w>k", opts)
vim.keymap.set("n", "<C-l>", "<C-w>l", opts)
-- Window navigation in insert mode with Ctrl + hjkl
vim.keymap.set("i", "<C-h>", "<C-w>", opts)

-- Use the black hole register for delete and change operations to avoid overwriting the default register.
vim.keymap.set("n", "d", '"_d', opts)
vim.keymap.set("n", "D", '"_D', opts)
vim.keymap.set("x", "d", '"_d', opts)
vim.keymap.set("n", "c", '"_c', opts)
vim.keymap.set("n", "C", '"_C', opts)
vim.keymap.set("x", "c", '"_c', opts)
vim.keymap.set("n", "x", '"_x', opts)

-- Use the system clipboard for copy and paste operations.
vim.keymap.set("n", "p", '"+p', opts)
vim.keymap.set("n", "P", '"+P', opts)
vim.keymap.set("x", "p", '"_d"+P', opts)
vim.keymap.set("x", "P", '"_d"+P', opts)

-- Custom keymaps for LSP, Copilot, and Markdown preview.
vim.keymap.set("n", "<leader>lsp", restart_lsp_and_copilot, { desc = "Restart LSP and Copilot" })
vim.keymap.set("n", "<leader>mv", toggle_markview, { desc = "Toggle Markdown preview" })

-- Navigate quickfix items with Ctrl + Shift + j/k and flash the landed line.
vim.keymap.set("n", "<C-S-j>", next_quickfix_item, { desc = "Next quickfix item" })
vim.keymap.set("n", "<C-S-k>", previous_quickfix_item, { desc = "Previous quickfix item" })
