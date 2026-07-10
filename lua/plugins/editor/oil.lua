-- Return the current file's directory, falling back to the working directory.
local function current_file_dir()
  local dir = vim.fn.expand("%:p:h")
  if dir == "" then
    return vim.uv.cwd()
  end
  return dir
end

-- Open Oil in the current window at the current file's directory.
local function open_oil()
  require("oil").open(current_file_dir())
end

-- Open Oil in a vertical split at the current file's directory.
local function open_oil_split()
  vim.cmd("vsplit")
  require("oil").open(current_file_dir())
end

-- Register file-browser mappings backed by Oil.
local function set_oil_keymaps()
  vim.keymap.set("n", "<leader>x", open_oil, { desc = "Open Oil file browser" })
  vim.keymap.set("n", "<leader>sp", open_oil_split, { desc = "Open Oil in vertical split" })
end

return {
  {
    "stevearc/oil.nvim",
    dependencies = {
      "nvim-tree/nvim-web-devicons",
    },
    lazy = false,
    opts = {
      default_file_explorer = true,
      delete_to_trash = true,
      watch_for_changes = true,
      columns = {
        "icon",
      },
      view_options = {
        show_hidden = true,
      },
    },
    -- Configure Oil and replace the old netrw file-browser mappings.
    config = function(_, opts)
      require("oil").setup(opts)
      set_oil_keymaps()
    end,
  },
}
