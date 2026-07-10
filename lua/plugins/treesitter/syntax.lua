return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "master",
    lazy = false,
    build = ":TSUpdate",
    opts = {
      ensure_installed = {
        "asm",
        "lua",
        "nasm",
        "rust",
        "toml",
        "vim",
        "vimdoc",
      },
      highlight = { enable = true },
      indent = { enable = true },
    },
    -- Apply the parser and highlighting options through nvim-treesitter.
    config = function(_, opts)
      require("nvim-treesitter.configs").setup(opts)
    end,
  },
}
