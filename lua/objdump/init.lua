local M = {}

local cache = {}

-- Decode the 7-character binutils flag field into readable words.
local function decode_flags(flags)
  local parts = {}
  local scope = flags:sub(1, 1)
  if scope == "l" then
    table.insert(parts, "local")
  elseif scope == "g" then
    table.insert(parts, "global")
  elseif scope == "u" then
    table.insert(parts, "unique-global")
  elseif scope == "!" then
    table.insert(parts, "global/local")
  end
  if flags:sub(2, 2) == "w" then
    table.insert(parts, "weak")
  end
  if flags:sub(3, 3) == "C" then
    table.insert(parts, "constructor")
  end
  if flags:sub(4, 4) == "W" then
    table.insert(parts, "warning")
  end
  local ref = flags:sub(5, 5)
  if ref == "I" then
    table.insert(parts, "indirect")
  elseif ref == "i" then
    table.insert(parts, "ifunc")
  end
  local dbg = flags:sub(6, 6)
  if dbg == "d" then
    table.insert(parts, "debug")
  elseif dbg == "D" then
    table.insert(parts, "dynamic")
  end
  local typ = flags:sub(7, 7)
  if typ == "F" then
    table.insert(parts, "function")
  elseif typ == "f" then
    table.insert(parts, "file")
  elseif typ == "O" then
    table.insert(parts, "object")
  end
  return parts
end

-- Parse the symbol table and disassembly into lookup tables for the buffer.
local function build_index(bufnr)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local symbols = {}
  local labels_by_name = {}
  local labels_by_addr = {}
  local addr_lines = {}
  local contents = {}
  local in_symtab = false
  local cur_contents = nil

  for i, line in ipairs(lines) do
    if line == "SYMBOL TABLE:" then
      in_symtab = true
    elseif line:find("^Disassembly of section") then
      in_symtab = false
      cur_contents = nil
    elseif line:find("^Contents of section") then
      in_symtab = false
      cur_contents = line:match("^Contents of section (%S+):")
      if cur_contents and not contents[cur_contents] then
        contents[cur_contents] = { header = i, lines = {} }
      end
    end

    if in_symtab then
      local value, flags, section, size, name =
        line:match("^(%x+) (.......) (%S+)\t(%x+) (.+)$")
      if value and name then
        symbols[name] = {
          value = value,
          flags = flags,
          section = section,
          size = size,
          lnum = i,
        }
      end
    elseif cur_contents then
      local caddr = line:match("^ (%x+) %x")
      if caddr then
        contents[cur_contents].lines[tonumber(caddr, 16)] = i
      end
    else
      local laddr, lname = line:match("^(%x+) <(.-)>:$")
      if laddr then
        labels_by_name[lname] = i
        labels_by_addr[tonumber(laddr, 16)] = i
      else
        local iaddr = line:match("^%s*(%x+):")
        if iaddr then
          addr_lines[tonumber(iaddr, 16)] = i
        end
      end
    end
  end

  return {
    tick = vim.api.nvim_buf_get_changedtick(bufnr),
    symbols = symbols,
    labels_by_name = labels_by_name,
    labels_by_addr = labels_by_addr,
    addr_lines = addr_lines,
    contents = contents,
  }
end

-- Return a cached index for the buffer, rebuilding when it changed.
local function index(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local cached = cache[bufnr]
  if cached and cached.tick == vim.api.nvim_buf_get_changedtick(bufnr) then
    return cached
  end
  cache[bufnr] = build_index(bufnr)
  return cache[bufnr]
end

-- Extract the symbol reference or bare word under the cursor.
local function context_under_cursor()
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2] + 1

  for s, inner, e in line:gmatch("()<([^>]*)>()") do
    if col >= s and col < e then
      return { kind = "ref", name = inner:match("^([^+%-]+)") }
    end
  end

  local rev = line:sub(1, col):match("[%w_.$]*$") or ""
  local fwd = line:sub(col + 1):match("^[%w_.$]*") or ""
  local word = rev .. fwd
  if word ~= "" then
    return { kind = "word", name = word }
  end
end

-- Move the cursor to a target line and recenter, recording the origin in the
-- jumplist so <C-o>/<C-i> navigate the jump history like in normal files.
local function jump_to_line(lnum)
  vim.cmd("normal! m'")
  vim.api.nvim_win_set_cursor(0, { lnum, 0 })
  vim.cmd("normal! zz")
end

-- Jump to the line in a "Contents of section" block that holds an address.
local function goto_contents(idx, section, addr)
  local sec = idx.contents[section]
  if not sec then
    return false
  end
  jump_to_line(sec.lines[addr - (addr % 16)] or sec.header)
  return true
end

-- Jump from a symbol reference or target address to its definition.
function M.goto_definition()
  local idx = index()

  -- On a symbol table row: code jumps to disassembly, data to section contents.
  local value, _, section, _, name =
    vim.api.nvim_get_current_line():match("^(%x+) (.......) (%S+)\t(%x+) (.+)$")
  if value then
    if idx.labels_by_name[name] then
      jump_to_line(idx.labels_by_name[name])
    elseif not goto_contents(idx, section, tonumber(value, 16)) then
      vim.notify("objdump: no section contents for '" .. name .. "'", vim.log.levels.INFO)
    end
    return
  end

  local ctx = context_under_cursor()
  if not ctx or not ctx.name then
    return
  end

  if ctx.name:match("^%x+$") then
    local addr = tonumber(ctx.name, 16)
    local target = idx.labels_by_addr[addr] or idx.addr_lines[addr]
    if target then
      jump_to_line(target)
      return
    end
  end

  if idx.labels_by_name[ctx.name] then
    jump_to_line(idx.labels_by_name[ctx.name])
    return
  end
  if idx.symbols[ctx.name] then
    jump_to_line(idx.symbols[ctx.name].lnum)
    return
  end

  vim.notify("objdump: no definition for '" .. ctx.name .. "'", vim.log.levels.INFO)
end

-- Build the markdown lines describing a symbol-table entry.
local function symbol_doc(name, sym)
  local flags = decode_flags(sym.flags)
  return {
    "# " .. name,
    "",
    "- value:   `0x" .. sym.value .. "`",
    "- section: `" .. sym.section .. "`",
    "- size:    `" .. (tonumber(sym.size, 16) or 0) .. "` (0x" .. sym.size .. ")",
    "- flags:   " .. (#flags > 0 and table.concat(flags, ", ") or "none"),
  }
end

-- Show the symbol-table entry for the token under the cursor in a float.
function M.hover()
  local idx = index()
  local ctx = context_under_cursor()
  if not ctx or not ctx.name then
    return
  end

  local name, sym = ctx.name, idx.symbols[ctx.name]

  if not sym and ctx.name:match("^%x+$") then
    local addr = tonumber(ctx.name, 16)
    local best
    for sname, s in pairs(idx.symbols) do
      local base, sz = tonumber(s.value, 16), tonumber(s.size, 16) or 0
      if base and addr >= base and addr < base + math.max(sz, 1) then
        if not best or base > tonumber(best.value, 16) then
          best, name = s, sname
        end
      end
    end
    sym = best
  end

  if not sym then
    vim.notify("objdump: no symbol info for '" .. name .. "'", vim.log.levels.INFO)
    return
  end

  vim.lsp.util.open_floating_preview(symbol_doc(name, sym), "markdown", {
    border = "rounded",
    focusable = false,
  })
end

-- Collect every line that references the symbol under the cursor.
function M.references()
  local bufnr = vim.api.nvim_get_current_buf()
  local ctx = context_under_cursor()
  if not ctx or not ctx.name then
    return
  end

  local pat = "<" .. vim.pesc(ctx.name) .. "[>+%-]"
  local items = {}
  for i, line in ipairs(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)) do
    if line:find(pat) then
      table.insert(items, { bufnr = bufnr, lnum = i, col = 1, text = vim.trim(line) })
    end
  end

  if #items == 0 then
    vim.notify("objdump: no references to '" .. ctx.name .. "'", vim.log.levels.INFO)
    return
  end

  vim.fn.setqflist({}, " ", { title = "objdump references: " .. ctx.name, items = items })
  vim.cmd("copen")
end

-- Browse every symbol with Telescope and jump to its definition.
function M.symbol_picker()
  local ok, pickers = pcall(require, "telescope.pickers")
  if not ok then
    vim.notify("objdump: telescope not available", vim.log.levels.WARN)
    return
  end
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")

  local idx = index()
  local bufnr = vim.api.nvim_get_current_buf()
  local fname = vim.api.nvim_buf_get_name(bufnr)

  local entries = {}
  for name, sym in pairs(idx.symbols) do
    entries[#entries + 1] = {
      name = name,
      sym = sym,
      lnum = idx.labels_by_name[name] or sym.lnum,
    }
  end
  table.sort(entries, function(a, b)
    return a.name < b.name
  end)

  pickers
    .new({}, {
      prompt_title = "Objdump Symbols",
      finder = finders.new_table({
        results = entries,
        entry_maker = function(e)
          return {
            value = e,
            display = string.format("%-40s %-14s 0x%s", e.name, e.sym.section, e.sym.value),
            ordinal = e.name,
            filename = fname ~= "" and fname or nil,
            lnum = e.lnum,
          }
        end,
      }),
      sorter = conf.generic_sorter({}),
      previewer = fname ~= "" and conf.grep_previewer({}) or nil,
      attach_mappings = function(prompt_bufnr)
        actions.select_default:replace(function()
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          if selection and selection.lnum then
            jump_to_line(selection.lnum)
          end
        end)
        return true
      end,
    })
    :find()
end

-- Fold sections at level 1 and each function block at level 2.
function M.foldexpr()
  local line = vim.fn.getline(vim.v.lnum)
  if line:find("^Disassembly of section") then
    return ">1"
  end
  if line:find("^%x+ <.->:$") then
    return ">2"
  end
  return "="
end

-- Render a closed fold as its header line plus a line count.
function M.foldtext()
  local count = vim.v.foldend - vim.v.foldstart + 1
  return vim.fn.getline(vim.v.foldstart) .. "  ... " .. count .. " lines"
end

vim.api.nvim_create_autocmd("BufWipeout", {
  group = vim.api.nvim_create_augroup("ObjdumpCache", { clear = true }),
  callback = function(args)
    cache[args.buf] = nil
  end,
})

return M
