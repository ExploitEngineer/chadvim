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

-- zls is NOT from mason: the zig toolchain here is a nightly (0.17.0-dev), and
-- mason only ships tagged zls releases, which refuse to run against dev zig.
-- A version-matched zls nightly is installed at ~/.local/bin/zls (on PATH, so
-- it auto-discovers the zig binary sitting next to it). Re-match after a zig
-- bump with the zigtools version selector:
--   https://releases.zigtools.org/v1/zls/select-version?zig_version=$(zig version)&compatibility=full
vim.lsp.config("zls", {
  -- pin the nightly binary explicitly: options.lua prepends mason/bin to PATH,
  -- so a stray mason zls (tagged, e.g. 0.16) would otherwise shadow this one
  -- and mismatch the nightly zig, which is what produced the degraded analysis.
  cmd = { vim.fn.expand "~/.local/bin/zls" },
  settings = {
    zls = {
      -- live compiler diagnostics: zls runs the build on save, so type/compile
      -- errors surface while typing instead of only at `zig build` time. In a
      -- large project add a `check` step to build.zig and point this at it via
      -- build_on_save_args = { "check" } to avoid emitting install artifacts.
      enable_build_on_save = true,

      -- richer completion: expand snippet bodies and fill argument placeholders
      enable_snippets = true,
      enable_argument_placeholders = true,

      -- full semantic highlighting + inlay hints (toggle hint display with
      -- vim.lsp.inlay_hint.enable if wanted; zls just provides the data here)
      semantic_tokens = "full",
      inlay_hints_show_variable_type_hints = true,
      inlay_hints_show_parameter_name = true,
      inlay_hints_show_builtin = true,
      inlay_hints_hide_redundant_param_names = true,
      inlay_hints_hide_redundant_param_names_last_token = true,

      warn_style = true,
      highlight_global_var_declarations = true,
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
  "zls",
}
