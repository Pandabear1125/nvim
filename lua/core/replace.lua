local M = {}

-- Record byte positions so replacements can run backwards without moving later matches.
local function find_matches(bufnr, search)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local contents = table.concat(lines, "\n")
  local matches = {}
  local row, line_start = 1, 0
  local offset = 1

  local function position(byte)
    while row < #lines and byte > line_start + #lines[row] do
      line_start = line_start + #lines[row] + 1
      row = row + 1
    end
    return row - 1, byte - line_start
  end

  while true do
    local first, last = contents:find(search, offset, true)
    if not first then
      return matches
    end

    local start_row, start_col = position(first - 1)
    local end_row, end_col = position(last)
    matches[#matches + 1] = {
      bufnr = bufnr,
      lnum = start_row + 1,
      col = start_col + 1,
      end_row = end_row,
      end_col = end_col,
      text = lines[start_row + 1],
    }
    offset = last + 1
  end
end

local function replace_matches(bufnr, changedtick, matches, search, replacement)
  if
    not vim.api.nvim_buf_is_valid(bufnr)
    or not vim.api.nvim_buf_is_loaded(bufnr)
    or not vim.bo[bufnr].modifiable
  then
    vim.notify("Replacement cancelled: buffer is no longer editable", vim.log.levels.WARN)
    return
  end
  if vim.api.nvim_buf_get_changedtick(bufnr) ~= changedtick then
    vim.notify("Replacement cancelled: buffer changed while the picker was open", vim.log.levels.WARN)
    return
  end
  if replacement == search then
    return
  end

  local replacement_lines = vim.split(replacement, "\n", { plain = true })
  vim.api.nvim_buf_call(bufnr, function()
    for i = #matches, 1, -1 do
      if i < #matches then
        vim.cmd("undojoin")
      end
      local match = matches[i]
      vim.api.nvim_buf_set_text(bufnr, match.lnum - 1, match.col - 1, match.end_row, match.end_col, replacement_lines)
    end
  end)
  vim.notify(string.format("Replaced %d occurrence(s)", #matches))
end

-- Use Telescope as a replacement field while keeping every affected match visible.
function M.visual()
  local bufnr = vim.api.nvim_get_current_buf()
  if not vim.bo[bufnr].modifiable then
    vim.notify("Cannot replace text in a non-editable buffer", vim.log.levels.WARN)
    return
  end

  local selection = vim.fn.getregion(vim.fn.getpos("v"), vim.fn.getpos("."), { type = vim.fn.mode() })
  local search = table.concat(selection, "\n")
  vim.cmd.normal({ args = { "\27" }, bang = true })
  if search == "" then
    return
  end

  local matches = find_matches(bufnr, search)
  if #matches == 0 then
    vim.notify("No exact matches in the current file", vim.log.levels.INFO)
    return
  end
  local changedtick = vim.api.nvim_buf_get_changedtick(bufnr)
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")

  require("telescope.pickers")
    .new({}, {
      prompt_title = "Replace with (Enter: apply all, Esc: cancel)",
      results_title = string.format("%d matches: %s", #matches, search:gsub("\n", "\\n")),
      initial_mode = "insert",
      sorting_strategy = "ascending",
      layout_config = { width = 0.7, height = 0.4, prompt_position = "top" },
      finder = require("telescope.finders").new_table({
        results = matches,
        entry_maker = function(match)
          return {
            value = match,
            bufnr = bufnr,
            lnum = match.lnum,
            col = match.col,
            ordinal = match.text,
            display = string.format("%d:%d: %s", match.lnum, match.col, match.text),
          }
        end,
      }),
      sorter = require("telescope.sorters").empty(),
      attach_mappings = function(_, map)
        actions.select_default:replace(function(prompt_bufnr)
          -- Read the buffer directly so Enter includes the latest typed character.
          local replacement = action_state.get_current_picker(prompt_bufnr):_get_prompt()
          actions.close(prompt_bufnr)
          replace_matches(bufnr, changedtick, matches, search, replacement)
        end)
        map("i", "<Esc>", actions.close)
        return true
      end,
    })
    :find()
end

return M
