local ignore_dirs = {
  "%.git/",
  "%.cache/",
  "%.venv/",
  "%arm-gnu-toolchain/",
}

local rg_excludes = {
  "--glob=!**/.git/*",
  "--glob=!**/.cache/*",
  "--glob=!**/.venv/*",
  "--glob=!**/arm-gnu-toolchain/*",
}

local fd_excludes = {
  "--exclude=.git",
  "--exclude=.cache",
  "--exclude=.venv",
  "--exclude=arm-gnu-toolchain",
}

-- Report whether native Telescope extensions can be built locally.
local function has_make()
  return vim.fn.executable("make") == 1
end

-- Build the ripgrep arguments used by hidden-file-aware searches.
local function hidden_rg_args()
  return vim.list_extend({
    "--hidden",
    "--no-ignore",
    "--no-ignore-parent",
    "--follow",
  }, rg_excludes)
end

-- Build a file finder command that prunes noisy directories before Telescope sees
-- the results, instead of only filtering them after the external job has walked.
local function hidden_find_command()
  if vim.fn.executable("fd") == 1 then
    return vim.list_extend({
      "fd",
      "--type",
      "f",
      "--color",
      "never",
      "--hidden",
      "--no-ignore",
      "--no-ignore-parent",
      "--follow",
    }, fd_excludes)
  end

  if vim.fn.executable("fdfind") == 1 then
    return vim.list_extend({
      "fdfind",
      "--type",
      "f",
      "--color",
      "never",
      "--hidden",
      "--no-ignore",
      "--no-ignore-parent",
      "--follow",
    }, fd_excludes)
  end

  if vim.fn.executable("rg") == 1 then
    return vim.list_extend({
      "rg",
      "--files",
      "--color",
      "never",
      "--hidden",
      "--no-ignore",
      "--no-ignore-parent",
      "--follow",
    }, rg_excludes)
  end
end

-- Telescope can assert when a still-streaming finder is cancelled and
-- libuv reports the closed pipe as a read error. Treat intentional close-time
-- pipe errors as EOF so cancelling a picker stays quiet.
local function patch_telescope_cancel_error()
  local telescope_async = require("telescope._")
  if telescope_async._cancel_error_patched then
    return
  end

  local channel = require("plenary.async").control.channel
  local LinesPipe = telescope_async.LinesPipe

  function LinesPipe:read()
    local read_tx, read_rx = channel.oneshot()

    self.handle:read_start(function(err, data)
      if err then
        if self._closed or self.handle:is_closing() then
          read_tx(nil)
          pcall(self.eof_tx)
          return
        end

        error(err)
      end

      self.handle:read_stop()

      read_tx(data)
      if data == nil then
        self.eof_tx()
      end
    end)

    return read_rx()
  end

  telescope_async._cancel_error_patched = true
end

-- Use Neovim's native Treesitter API because nvim-treesitter main removed
-- the parser helpers used by older Telescope releases.
local function patch_telescope_treesitter()
  local preview_utils = require("telescope.previewers.utils")
  if preview_utils._native_treesitter_patched then
    return
  end

  preview_utils.ts_highlighter = function(bufnr, ft)
    if not ft or ft == "" then
      return false
    end

    local lang = vim.treesitter.language.get_lang(ft) or ft
    local parser_ok, parser_available = pcall(vim.treesitter.language.add, lang)
    if not parser_ok or not parser_available then
      return false
    end

    return pcall(vim.treesitter.start, bufnr, lang)
  end

  preview_utils._native_treesitter_patched = true
end

-- Open Telescope's file picker with hidden and ignored files included.
local function find_files()
  local opts = {
    find_command = hidden_find_command(),
    file_ignore_patterns = ignore_dirs,
  }

  if opts.find_command == nil then
    opts.hidden = true
    opts.no_ignore = true
    opts.no_ignore_parent = true
    opts.follow = true
  end

  require("telescope.builtin").find_files(opts)
end

-- Search text across hidden and ignored files with the shared ignore rules.
local function live_grep()
  require("telescope.builtin").live_grep({
    additional_args = hidden_rg_args,
  })
end

-- Return the current visual selection as plain text for grep_string.
local function get_visual_selection_text()
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "x", false)

  local _, start_line, start_col = unpack(vim.fn.getpos("'<"))
  local _, end_line, end_col = unpack(vim.fn.getpos("'>"))
  local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)

  if #lines == 0 then
    return ""
  end

  lines[#lines] = string.sub(lines[#lines], 1, end_col)
  lines[1] = string.sub(lines[1], start_col)

  return table.concat(lines, "\n")
end

-- Search for the current visual selection with Telescope.
local function grep_visual_selection()
  local text = get_visual_selection_text():gsub("^%s+", ""):gsub("%s+$", "")
  if text ~= "" then
    require("telescope.builtin").grep_string({
      search = text,
      initial_mode = "normal",
      additional_args = hidden_rg_args,
    })
  end
end

-- Configure Telescope mappings that export picker results to quickfix.
local function setup_telescope()
  local actions = require("telescope.actions")

  patch_telescope_cancel_error()
  patch_telescope_treesitter()

  require("telescope").setup({
    defaults = {
      mappings = {
        i = {
          ["<C-q>"] = actions.send_to_qflist + actions.open_qflist,
          ["<M-q>"] = actions.add_to_qflist + actions.open_qflist,
        },
        n = {
          ["<C-q>"] = actions.send_to_qflist + actions.open_qflist,
          ["<M-q>"] = actions.add_to_qflist + actions.open_qflist,
        },
      },
    },
  })
end

-- Register the Telescope search mappings from the old config.
local function set_search_keymaps()
  vim.keymap.set("n", "<leader>ff", find_files, { desc = "Find files" })
  vim.keymap.set("n", "<leader>gf", live_grep, { desc = "Grep files" })
  vim.keymap.set("n", "<leader>fs", live_grep, { desc = "Search text" })
  vim.keymap.set("v", "<leader>gs", grep_visual_selection, {
    noremap = true,
    silent = true,
    desc = "Search visual selection",
  })
end

return {
  {
    "nvim-telescope/telescope.nvim",
    tag = "v0.2.2",
    dependencies = {
      "nvim-lua/plenary.nvim",
      {
        "nvim-telescope/telescope-fzf-native.nvim",
        build = "make",
        cond = has_make,
      },
    },
    -- Configure Telescope and register the search mappings.
    config = function()
      setup_telescope()
      set_search_keymaps()
    end,
  },
}
