local M = {}
local active
local method = "textDocument/hover"
local diagnostic_ns = vim.api.nvim_create_namespace("core.hover.diagnostics")

-- Keep diagnostic messages and plaintext documentation literal inside Markdown.
local function literal_block(lines)
  local fence_length = 3
  for _, line in ipairs(lines) do
    for backticks in line:gmatch("`+") do
      fence_length = math.max(fence_length, #backticks + 1)
    end
  end
  local fence = string.rep("`", fence_length)
  local contents = { fence .. "text" }
  vim.list_extend(contents, lines)
  contents[#contents + 1] = fence
  return contents
end

local function documentation_lines(results)
  local contents = {}
  local client_ids = vim.tbl_keys(results)
  table.sort(client_ids)
  for _, client_id in ipairs(client_ids) do
    local response = results[client_id]
    local result = not response.err and not response.error and response.result
    if result and result.contents then
      local lines = vim.lsp.util.convert_input_to_markdown_lines(result.contents)
      if table.concat(lines, ""):find("%S") then
        if type(result.contents) == "table" and result.contents.kind == "plaintext" then
          lines = literal_block(lines)
        end
        if #contents > 0 then
          contents[#contents + 1] = "---"
        end
        vim.list_extend(contents, lines)
      end
    end
  end
  return contents
end

local function same_location(state)
  return vim.api.nvim_buf_is_valid(state.bufnr)
    and vim.api.nvim_win_is_valid(state.source_win)
    and vim.api.nvim_win_get_buf(state.source_win) == state.bufnr
    and vim.api.nvim_win_is_valid(state.float_win)
    and vim.api.nvim_buf_get_changedtick(state.bufnr) == state.changedtick
    and vim.deep_equal(vim.api.nvim_win_get_cursor(state.source_win), state.cursor)
end

function M.show()
  local bufnr = vim.api.nvim_get_current_buf()
  local source_win = vim.api.nvim_get_current_win()
  if active and active.source_win == source_win and same_location(active) then
    vim.api.nvim_set_current_win(active.float_win)
    return
  end

  local previous = active
  active = nil
  if previous and previous.cancel then
    previous.cancel()
  end

  -- Reuse Neovim's diagnostic formatting and multiline range handling.
  local diagnostic_buf, float_win = vim.diagnostic.open_float({
    scope = "line",
    focus = false,
    source = "always",
  })
  if not diagnostic_buf then
    vim.lsp.buf.hover()
    return
  end

  local diagnostics = vim.api.nvim_buf_get_lines(diagnostic_buf, 0, -1, false)
  local highlights = vim.api.nvim_buf_get_extmarks(diagnostic_buf, -1, 0, -1, {
    details = true,
    type = "highlight",
  })
  local state = {
    bufnr = bufnr,
    source_win = source_win,
    float_win = float_win,
    cursor = vim.api.nvim_win_get_cursor(source_win),
    changedtick = vim.api.nvim_buf_get_changedtick(bufnr),
  }
  active = state
  if #vim.lsp.get_clients({ bufnr = bufnr, method = method }) == 0 then
    return
  end

  state.cancel = vim.lsp.buf_request_all(bufnr, method, function(client)
    return vim.lsp.util.make_position_params(source_win, client.offset_encoding)
  end, function(results)
    local current_win = vim.api.nvim_get_current_win()
    if active ~= state or not same_location(state) then
      return
    end
    if current_win ~= source_win and current_win ~= state.float_win then
      return
    end

    local documentation = documentation_lines(results)
    if #documentation == 0 then
      return
    end
    local contents = literal_block(diagnostics)
    vim.list_extend(contents, { "", "## Documentation", "" })
    vim.list_extend(contents, documentation)

    local focused = current_win == state.float_win
    local view = focused and vim.fn.winsaveview()
    if focused then
      vim.api.nvim_set_current_win(source_win)
    end
    local updated_buf, updated_win = vim.lsp.util.open_floating_preview(contents, "markdown", {
      focus = false,
      focus_id = method,
    })
    -- The opening code fence shifts diagnostics down one buffer line.
    for _, mark in ipairs(highlights) do
      local hl = mark[4]
      if hl.hl_group then
        vim.api.nvim_buf_set_extmark(updated_buf, diagnostic_ns, mark[2] + 1, mark[3], {
          end_row = hl.end_row + 1,
          end_col = hl.end_col,
          hl_group = hl.hl_group,
          priority = math.max(hl.priority or 0, vim.hl.priorities.user),
        })
      end
    end
    vim.wo[updated_win].concealcursor = "n"
    state.float_win = updated_win
    if focused then
      vim.api.nvim_set_current_win(updated_win)
      vim.fn.winrestview(view)
    end
  end)
end

return M
