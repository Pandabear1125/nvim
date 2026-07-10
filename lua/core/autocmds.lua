local group = vim.api.nvim_create_augroup("UserCore", { clear = true })

-- Briefly highlight text after a yank so the copied range is visible.
vim.api.nvim_create_autocmd("TextYankPost", {
  group = group,
  desc = "Highlight on yank/copy",
  callback = function()
    vim.hl.on_yank({ timeout = 300 })
  end,
})

-- Prevent Neovim from automatically continuing comments on new lines.
vim.api.nvim_create_autocmd("FileType", {
  group = group,
  pattern = "*",
  desc = "Do not continue comments when pressing Enter or using o/O",
  callback = function()
    vim.opt_local.formatoptions:remove({ "r", "o" })
  end,
})

-- Keep Rust buffers on four-space indentation while still using spaces.
vim.api.nvim_create_autocmd("FileType", {
  group = group,
  pattern = "rust",
  desc = "Use Rust indentation preferences",
  callback = function()
    vim.opt_local.tabstop = 4
    vim.opt_local.shiftwidth = 4
    vim.opt_local.expandtab = true
  end,
})

-- Check whether files changed on disk when focus or buffer state changes.
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold", "CursorHoldI" }, {
  group = group,
  desc = "Reload files changed on disk",
  callback = function()
    if vim.fn.mode() ~= "c" and vim.fn.reg_recording() == "" and vim.fn.reg_executing() == "" then
      vim.cmd("checktime")
    end
  end,
})

-- Notify when Neovim reloads a file because the on-disk copy changed.
vim.api.nvim_create_autocmd("FileChangedShellPost", {
  group = group,
  desc = "Notify when autoread reloads a file",
  callback = function()
    vim.notify("File reloaded (changed on disk)", vim.log.levels.INFO, { title = "autoread" })
  end,
})
