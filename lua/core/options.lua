vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

local opt = vim.opt

opt.autoread = true
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
