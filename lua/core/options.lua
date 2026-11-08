vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

local opt = vim.opt

opt.autoread = true

-- Use the Windows clipboard in WSL instead of an unrelated Linux clipboard.
if vim.fn.has("wsl") == 1 then
  local paste = {
    "powershell.exe", "-NoLogo", "-NoProfile", "-Command",
    '[Console]::Out.Write(([string](Get-Clipboard -Raw)).Replace("`r", ""))',
  }
  vim.g.clipboard = {
    name = "Windows clipboard",
    copy = {
      ["+"] = { "clip.exe" },
      ["*"] = { "clip.exe" },
    },
    paste = {
      ["+"] = paste,
      ["*"] = paste,
    },
    cache_enabled = 0,
  }
end

opt.clipboard = "unnamedplus"
opt.expandtab = false
opt.number = true
opt.relativenumber = false
opt.shiftwidth = 4
opt.signcolumn = "number"
opt.tabstop = 4
opt.undofile = true
opt.undodir = vim.fn.stdpath("data") .. "/undo"
opt.undolevels = 1000000
opt.undoreload = 1000000
opt.updatetime = 500
