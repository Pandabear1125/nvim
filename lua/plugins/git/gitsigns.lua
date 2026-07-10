return {
  {
    "lewis6991/gitsigns.nvim",
    -- Configure inline Git blame metadata for the statusline.
    config = function()
      require("gitsigns").setup({
        current_line_blame = true,
        current_line_blame_opts = {
          virt_text = false,
          delay = 0,
        },
      })
    end,
  },
}
