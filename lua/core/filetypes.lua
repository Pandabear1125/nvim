-- Recognize objdump disassembly output (e.g. *.dump) by its header so unrelated
-- .dump files fall through to default detection.
local function detect_objdump(_, bufnr)
  for _, line in ipairs(vim.api.nvim_buf_get_lines(bufnr, 0, 12, false)) do
    if line:find("file format", 1, true)
      or line:find("Disassembly of section", 1, true)
      or line == "SYMBOL TABLE:"
    then
      return "objdump"
    end
  end
end

-- Treat common assembly source extensions as assembly buffers.
vim.filetype.add({
  extension = {
    asm = "asm",
    inc = "asm",
    nasm = "nasm",
    s = "asm",
    S = "asm",
    dump = detect_objdump,
  },
})
