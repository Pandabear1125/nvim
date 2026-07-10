return {
  {
    "github/copilot.vim",
    -- Enable Copilot and define the insert-mode suggestion controls.
    config = function()
      vim.g.copilot_filetypes = {}
      vim.g.copilot_enabled = true
      vim.g.copilot_workspace_folders = {}

      vim.keymap.set("i", "<D-l>", "<Plug>(copilot-accept-word)", { silent = true })
      vim.keymap.set("i", "<D-j>", "<Plug>(copilot-dismiss)", { silent = true })
      vim.keymap.set("i", "<D-k>", "<Plug>(copilot-accept-line)", { silent = true })
    end,
  },
}
