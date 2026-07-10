return {
  {
    "ray-x/lsp_signature.nvim",
    event = "LspAttach",
    opts = {
      bind = true,
      floating_window = true,
      floating_window_above_cur_line = true,
      hint_enable = false,
      hi_parameter = "LspSignatureActiveParameter",
      handler_opts = {
        border = "rounded",
      },
    },
  },
}
