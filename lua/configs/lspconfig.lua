-- LSP setup: NvChad defaults + LazyVim-style buffer keymaps + per-server tweaks.
-- Uses the nvim 0.11+ vim.lsp.config/vim.lsp.enable API.

local nvlsp = require "nvchad.configs.lspconfig"

-- Replace NvChad's on_attach BEFORE defaults(): the LspAttach autocmd it
-- registers looks up M.on_attach at event time, so this swaps the keymaps.
-- Intentionally absent: NvChad's buffer-local <leader>D (type definition,
-- would shadow the global DBUI toggle) and <leader>wa/wr/wl.
nvlsp.on_attach = function(_, bufnr)
  local map = vim.keymap.set
  local function opts(desc)
    return { buffer = bufnr, desc = "LSP " .. desc }
  end

  map("n", "gd", "<cmd>Telescope lsp_definitions<CR>", opts "Goto definition")
  map("n", "gr", "<cmd>Telescope lsp_references<CR>", opts "References")
  map("n", "gI", "<cmd>Telescope lsp_implementations<CR>", opts "Goto implementation")
  map("n", "gy", "<cmd>Telescope lsp_type_definitions<CR>", opts "Goto type definition")
  map("n", "gD", vim.lsp.buf.declaration, opts "Goto declaration")
  map("n", "K", vim.lsp.buf.hover, opts "Hover")
  map("n", "gK", vim.lsp.buf.signature_help, opts "Signature help")
  map("i", "<C-k>", vim.lsp.buf.signature_help, opts "Signature help")
  map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts "Code action")
  map("n", "<leader>cr", vim.lsp.buf.rename, opts "Rename")
  map("n", "<leader>ra", vim.lsp.buf.rename, opts "Rename")
  map("n", "<leader>ss", "<cmd>Telescope lsp_document_symbols<CR>", opts "Document symbols")
  map("n", "<leader>sS", "<cmd>Telescope lsp_dynamic_workspace_symbols<CR>", opts "Workspace symbols")
end

nvlsp.defaults() -- diagnostics, capabilities, lua_ls (configured + enabled here)

vim.lsp.config("clangd", {
  cmd = {
    "clangd",
    "--background-index",
    "--clang-tidy",
    "--header-insertion=iwyu",
    "--completion-style=detailed",
    "--fallback-style=llvm",
  },
  capabilities = { offsetEncoding = { "utf-16" } },
})

vim.lsp.config("basedpyright", {
  settings = {
    basedpyright = {
      analysis = { typeCheckingMode = "standard" },
      disableOrganizeImports = true, -- ruff owns import organization
    },
  },
})

vim.lsp.config("ruff", {
  on_attach = function(client)
    client.server_capabilities.hoverProvider = false -- basedpyright owns hover
  end,
})

vim.lsp.config("gopls", {
  settings = {
    gopls = {
      gofumpt = true,
      staticcheck = true,
      usePlaceholders = true,
    },
  },
})

vim.lsp.config("jsonls", {
  settings = {
    json = {
      schemas = require("schemastore").json.schemas(),
      validate = { enable = true },
    },
  },
})

vim.lsp.config("yamlls", {
  settings = {
    yaml = {
      schemaStore = { enable = false, url = "" }, -- schemastore.nvim replaces the built-in store
      schemas = require("schemastore").yaml.schemas(),
    },
  },
})

-- NOT lua_ls (defaults() enables it) and NOT rust_analyzer (rustaceanvim owns
-- it — enabling both attaches two clients)
vim.lsp.enable {
  "clangd",
  "basedpyright",
  "ruff",
  "vtsls",
  "biome",
  "gopls",
  "html",
  "cssls",
  "tailwindcss",
  "jsonls",
  "yamlls",
  "bashls",
  "dockerls",
  "asm_lsp",
}
