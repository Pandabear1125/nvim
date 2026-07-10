-- Decide whether a diagnostic points at a real line in the buffer.
local function diagnostic_has_valid_line(line_count, diagnostic)
  return type(diagnostic.lnum) == "number"
    and diagnostic.lnum >= 0
    and diagnostic.lnum < line_count
end

-- Draw Error Lens highlights for valid diagnostics only.
local function show_error_lens(_, bufnr, diagnostics, _)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end

  local highlight = require("error-lens.highlight")
  local line_count = vim.api.nvim_buf_line_count(bufnr)
  local valid_diagnostics = {}

  for _, diagnostic in ipairs(diagnostics) do
    if diagnostic_has_valid_line(line_count, diagnostic) then
      table.insert(valid_diagnostics, diagnostic)
    end
  end

  local ok = pcall(highlight.update_highlights, bufnr, valid_diagnostics)
  if not ok then
    pcall(highlight.clear_highlights, bufnr)
  end
end

-- Clear Error Lens highlights when diagnostics disappear or refresh.
local function hide_error_lens(_, bufnr)
  if vim.api.nvim_buf_is_valid(bufnr) then
    pcall(require("error-lens.highlight").clear_highlights, bufnr)
  end
end

return {
  {
    "chikko80/error-lens.nvim",
    event = "BufRead",
    dependencies = { "nvim-telescope/telescope.nvim" },
    opts = {
      enabled = true,
      auto_adjust = {
        enable = false,
        fallback_bg_color = nil,
        step = 7,
        total = 30,
      },
      prefix = 4,
      colors = {
        error_fg = "#FF6363",
        error_bg = "#4B252C",
        warn_fg = "#FA973A",
        warn_bg = "#403733",
        info_fg = "#5B38E8",
        info_bg = "#281478",
        hint_fg = "#25E64B",
        hint_bg = "#147828",
      },
    },
    -- Register Error Lens and route diagnostics through its highlight handler.
    config = function(_, opts)
      require("error-lens").setup(opts)

      vim.diagnostic.handlers.error_lens = {
        show = show_error_lens,
        hide = hide_error_lens,
      }
    end,
  },
}
