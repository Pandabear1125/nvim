return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false,
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter").setup()

      local ensure_installed = {
        "asm",
        "lua",
        "nasm",
        "rust",
        "toml",
        "vim",
        "vimdoc",
      }
      local installed = require("nvim-treesitter.config").get_installed()
      local to_install = vim.iter(ensure_installed)
        :filter(function(parser)
          return not vim.tbl_contains(installed, parser)
        end)
        :totable()
      if #to_install > 0 then
        require("nvim-treesitter").install(to_install)
      end

      -- The main branch installs parsers only; features must be enabled per buffer.
      vim.api.nvim_create_autocmd("FileType", {
        callback = function()
          pcall(vim.treesitter.start)
          vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end,
      })
    end,
  },
}
