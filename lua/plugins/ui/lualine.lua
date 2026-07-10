-- Format gitsigns blame data into compact author and age text.
local function blame_line()
  local dict = vim.b.gitsigns_blame_line_dict
  if not dict then
    return "NIL"
  elseif dict.author == "Not Committed Yet" then
    return "You"
  end

  local diff = os.difftime(os.time(), dict.author_time)
  local minutes = math.floor(diff / 60)
  local hours = math.floor(minutes / 60)
  local days = math.floor(hours / 24)
  local time_str

  if days >= 30 then
    time_str = string.format("%dmo ago", math.floor(days / 30))
  elseif days >= 7 then
    time_str = string.format("%dw ago", math.floor(days / 7))
  elseif days > 0 then
    time_str = string.format("%dd ago", days)
  elseif hours > 0 then
    time_str = string.format("%dh ago", hours)
  elseif minutes > 0 then
    time_str = string.format("%dm ago", minutes)
  else
    time_str = "just now"
  end

  return string.format("%s:%s", dict.author, time_str)
end

-- Display the file line-ending format using familiar names.
local function eol_format()
  local fileformat = vim.bo.fileformat
  if fileformat == "unix" then
    return "LF"
  elseif fileformat == "dos" then
    return "CRLF"
  elseif fileformat == "mac" then
    return "CR"
  end
  return fileformat
end

-- Show the current cursor position alongside the total line count.
local function line_info()
  return string.format("%d:%d / %d", vim.fn.line("."), vim.fn.col("."), vim.fn.line("$"))
end

return {
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    -- Build the statusline using the old Gruvbox/lualine layout.
    config = function()
      require("lualine").setup({
        options = {
          theme = "gruvbox",
          globalstatus = true,
        },
        sections = {
          lualine_a = { "mode" },
          lualine_b = { "branch", "diff", "diagnostics" },
          lualine_c = { "filename", blame_line },
          lualine_x = { eol_format, "filetype" },
          lualine_y = {},
          lualine_z = { line_info },
        },
      })
    end,
  },
}
