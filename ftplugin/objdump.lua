-- Buffer-local behavior for objdump disassembly files.
local objdump = require("objdump")

vim.bo.commentstring = "@ %s"
vim.opt_local.wrap = false

-- Fold each section and function block, but leave everything open on load.
vim.opt_local.foldmethod = "expr"
vim.opt_local.foldexpr = "v:lua.require'objdump'.foldexpr()"
vim.opt_local.foldtext = "v:lua.require'objdump'.foldtext()"
vim.opt_local.foldenable = true
vim.opt_local.foldlevel = 99

-- Mirror the LSP navigation keys inside objdump buffers.
local function map(lhs, rhs, desc)
  vim.keymap.set("n", lhs, rhs, { buffer = true, silent = true, desc = desc })
end

map("gd", objdump.goto_definition, "Objdump: go to definition")
map("K", objdump.hover, "Objdump: hover symbol")
map("gr", objdump.references, "Objdump: list references")
map("<leader>ds", objdump.symbol_picker, "Objdump: symbol picker")
