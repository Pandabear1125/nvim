local opts = { noremap = true, silent = true }
local term_bufnr = nil
local last_winid, last_bufnr, last_cursor = nil, nil, nil

-- Leave terminal mode with Escape and allow window navigation from terminals.
vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]], opts)
vim.keymap.set("t", "<C-h>", [[<C-\><C-n><C-w>h]], opts)
vim.keymap.set("t", "<C-j>", [[<C-\><C-n><C-w>j]], opts)
vim.keymap.set("t", "<C-k>", [[<C-\><C-n><C-w>k]], opts)
vim.keymap.set("t", "<C-l>", [[<C-\><C-n><C-w>l]], opts)

-- Reopen the saved terminal buffer in a bottom split.
local function open_term_window()
  vim.cmd("botright 10split")
  local win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_height(win, 10)
  vim.api.nvim_win_set_buf(win, term_bufnr)
  vim.cmd("startinsert")
end

-- Create the persistent terminal buffer and hide it from buffer lists.
local function create_terminal()
  vim.cmd("botright 10split")
  vim.api.nvim_win_set_height(0, 10)
  vim.cmd("term")
  term_bufnr = vim.api.nvim_get_current_buf()
  vim.bo[term_bufnr].buflisted = false
  vim.bo[term_bufnr].bufhidden = "hide"
  vim.cmd("startinsert")
end

-- Show or hide the persistent terminal without killing its running job.
local function toggle_terminal()
  if term_bufnr and vim.api.nvim_buf_is_valid(term_bufnr) then
    local winid = vim.fn.bufwinid(term_bufnr)
    if winid ~= -1 then
      vim.api.nvim_set_current_win(winid)
      vim.cmd("hide")
    else
      open_term_window()
    end
  else
    create_terminal()
  end
end

-- Jump between the terminal and the previous editing location.
local function jump_terminal_focus()
  local cur_win = vim.api.nvim_get_current_win()
  local term_win = (term_bufnr and vim.api.nvim_buf_is_valid(term_bufnr)) and vim.fn.bufwinid(term_bufnr) or -1

  if term_win ~= -1 then
    if cur_win == term_win then
      if last_winid and vim.api.nvim_win_is_valid(last_winid) then
        if vim.bo.buftype == "terminal" then
          vim.cmd("stopinsert")
        end
        vim.api.nvim_set_current_win(last_winid)
        if last_bufnr and vim.api.nvim_buf_is_valid(last_bufnr)
          and vim.api.nvim_get_current_buf() == last_bufnr
          and last_cursor then
          pcall(vim.api.nvim_win_set_cursor, 0, last_cursor)
        end
      else
        if vim.bo.buftype == "terminal" then
          vim.cmd("stopinsert")
        end
        vim.cmd("wincmd p")
      end
      last_winid, last_bufnr, last_cursor = nil, nil, nil
      return
    end

    last_winid = cur_win
    last_bufnr = vim.api.nvim_get_current_buf()
    last_cursor = vim.api.nvim_win_get_cursor(0)
    vim.api.nvim_set_current_win(term_win)
    vim.cmd("startinsert")
    return
  end

  last_winid = cur_win
  last_bufnr = vim.api.nvim_get_current_buf()
  last_cursor = vim.api.nvim_win_get_cursor(0)

  if term_bufnr and vim.api.nvim_buf_is_valid(term_bufnr) then
    open_term_window()
  else
    create_terminal()
  end
end

vim.keymap.set("n", "<leader>t", toggle_terminal, { desc = "Toggle bottom terminal" })
vim.keymap.set({ "n", "t" }, "<C-`>", jump_terminal_focus, { desc = "Jump to terminal or back" })

-- Keep terminal windows readable by disabling relative numbers.
vim.api.nvim_create_autocmd("TermOpen", {
  group = vim.api.nvim_create_augroup("UserTerminal", { clear = true }),
  callback = function()
    vim.opt_local.number = true
    vim.opt_local.relativenumber = false
  end,
})

-- Forget the saved terminal buffer after its job exits.
vim.api.nvim_create_autocmd("TermClose", {
  group = vim.api.nvim_create_augroup("UserTerminalClose", { clear = true }),
  callback = function(args)
    if args.buf == term_bufnr then
      term_bufnr = nil
    end
  end,
})
