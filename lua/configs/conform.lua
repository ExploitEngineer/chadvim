local options = {
  formatters_by_ft = {
    lua = { "stylua" },
    c = { "clang-format" },
    cpp = { "clang-format" },
    rust = { "rustfmt" }, -- system rust toolchain, not mason
    python = { "ruff_organize_imports", "ruff_format" },
    go = { "goimports", "gofumpt" },
    javascript = { "biome" },
    typescript = { "biome" },
    javascriptreact = { "biome" },
    typescriptreact = { "biome" },
    json = { "biome" },
    jsonc = { "biome" },
    -- biome doesn't cover these:
    css = { "prettier" },
    scss = { "prettier" },
    html = { "prettier" },
    markdown = { "prettier" },
    yaml = { "prettier" },
    graphql = { "prettier" },
    sh = { "shfmt" },
    bash = { "shfmt" },
    zsh = { "shfmt" },
  },

  format_on_save = function(bufnr)
    -- <leader>uf toggles vim.g.autoformat, <leader>uF toggles vim.b.autoformat
    if not vim.g.autoformat or vim.b[bufnr].autoformat == false then
      return
    end
    return { timeout_ms = 1000, lsp_format = "fallback" }
  end,
}

return options
