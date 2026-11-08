-- Create a buffer-local mapping for an attached LSP client.
local function buffer_map(bufnr, mode, lhs, rhs, desc)
  vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, silent = true, desc = desc })
end

-- Format the current buffer through the attached language server.
local function format_buffer()
  vim.lsp.buf.format({ async = true })
end

-- Jump to the previous diagnostic and show its floating message.
local function previous_diagnostic()
  vim.diagnostic.jump({ count = -1, float = true })
end

-- Jump to the next diagnostic and show its floating message.
local function next_diagnostic()
  vim.diagnostic.jump({ count = 1, float = true })
end

-- Print the current LSP workspace folders for quick inspection.
local function print_workspace_folders()
  print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
end

-- Install and configure external language servers through Mason.
local function setup_mason()
  require("mason").setup()
  require("mason-lspconfig").setup({
    ensure_installed = {
      "asm_lsp",
      "lua_ls",
      "rust_analyzer",
    },
    automatic_enable = false,
  })
end

-- Attach buffer-local LSP navigation, action, formatting, and diagnostic maps.
local function lsp_on_attach(_, bufnr)
  buffer_map(bufnr, "n", "gd", vim.lsp.buf.definition, "Go to definition")
  buffer_map(bufnr, "n", "gD", vim.lsp.buf.declaration, "Go to declaration")
  buffer_map(bufnr, "n", "gi", vim.lsp.buf.implementation, "Go to implementation")
  buffer_map(bufnr, "n", "gt", vim.lsp.buf.type_definition, "Go to type definition")
  buffer_map(bufnr, "n", "gr", vim.lsp.buf.references, "List references")
  buffer_map(bufnr, "n", "K", function()
    require("core.hover").show()
  end, "Hover documentation and line diagnostics")
  buffer_map(bufnr, "n", "<leader>rn", vim.lsp.buf.rename, "Rename symbol")
  buffer_map(bufnr, { "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, "Code action")
  buffer_map(bufnr, { "n", "v" }, "<leader>f", format_buffer, "Format")
  buffer_map(bufnr, "n", "gl", vim.diagnostic.open_float, "Line diagnostics")
  buffer_map(bufnr, "n", "[d", previous_diagnostic, "Previous diagnostic")
  buffer_map(bufnr, "n", "]d", next_diagnostic, "Next diagnostic")
  buffer_map(bufnr, "n", "<leader>q", vim.diagnostic.setloclist, "Diagnostics to loclist")
  buffer_map(bufnr, "n", "<leader>wa", vim.lsp.buf.add_workspace_folder, "Add workspace folder")
  buffer_map(bufnr, "n", "<leader>wr", vim.lsp.buf.remove_workspace_folder, "Remove workspace folder")
  buffer_map(bufnr, "n", "<leader>wl", print_workspace_folders, "List workspace folders")
end

-- Build client capabilities, adding nvim-cmp support when available.
local function capabilities()
  local ok, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
  if ok then
    return cmp_nvim_lsp.default_capabilities()
  end
  return vim.lsp.protocol.make_client_capabilities()
end

-- Attach lsp_signature for language servers where signature help is useful.
local function attach_signature(args)
  local client = vim.lsp.get_client_by_id(args.data.client_id)
  if client and (client.name == "clangd" or client.name == "rust_analyzer") then
    local ok, lsp_signature = pcall(require, "lsp_signature")
    if ok then
      lsp_signature.on_attach({
        bind = true,
        handler_opts = { border = "rounded" },
      }, args.buf)
    end
  end
end

return {
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "mason-org/mason.nvim",
      "mason-org/mason-lspconfig.nvim",
      "hrsh7th/cmp-nvim-lsp",
      "ray-x/lsp_signature.nvim",
      {
        "folke/lazydev.nvim",
        ft = "lua",
        opts = {
          library = {
            { path = "${3rd}/luv/library", words = { "vim%.uv" } },
          },
        },
      },
    },
    -- Configure the language servers carried over from the old config.
    config = function()
      setup_mason()

      vim.lsp.config("lua_ls", {
        capabilities = capabilities(),
        on_attach = lsp_on_attach,
        settings = {
          Lua = {
            completion = {
              callSnippet = "Replace",
            },
            diagnostics = {
              globals = { "vim" },
            },
            hint = {
              enable = true,
            },
            runtime = {
              version = "LuaJIT",
            },
            workspace = {
              checkThirdParty = false,
              library = vim.api.nvim_get_runtime_file("", true),
            },
          },
        },
      })
      vim.lsp.enable("lua_ls")

      vim.lsp.config("asm_lsp", {
        capabilities = capabilities(),
        on_attach = lsp_on_attach,
      })
      vim.lsp.enable("asm_lsp")

      vim.lsp.config("clangd", {
        cmd = {
          "clangd",
          "--background-index-priority=normal",
          "--background-index",
          "--clang-tidy",
          "--enable-config",
          "--fallback-style=LLVM",
          "--limit-references=0",
          "--limit-results=0",
          "--log=error",
          "--pretty",
          "--header-insertion=never",
          "--query-driver=**/arm-none-eabi-*,/opt/homebrew/bin/*,/usr/local/bin/*",
        },
        capabilities = capabilities(),
        on_attach = lsp_on_attach,
      })
      vim.lsp.enable("clangd")

      vim.lsp.config("rust_analyzer", {
        capabilities = capabilities(),
        on_attach = lsp_on_attach,
        settings = {
          ["rust-analyzer"] = {
            cargo = { allTargets = false },
            cachePriming = { enable = false },
            check = {
              allTargets = false,
              command = "clippy",
            },
            diagnostics = {
              enable = true,
            },
            procMacro = {
              enable = true,
            },
          },
        },
      })
      vim.lsp.enable("rust_analyzer")

      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("UserLspSignature", { clear = true }),
        callback = attach_signature,
      })
    end,
  },
}
