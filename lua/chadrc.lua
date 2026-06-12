-- This file needs to have same structure as nvconfig.lua
-- https://github.com/NvChad/ui/blob/v3.0/lua/nvconfig.lua

---@type ChadrcConfig
local M = {}

M.base46 = {
  theme = "ayu_dark",

  -- compile theme colors for these added plugins too (loaded in options.lua)
  integrations = { "dap", "diffview", "flash", "trouble", "todo", "grug_far" },

  hl_override = {
    -- base46 has no lazy.nvim integration; Lazy's own defaults (CursorLine
    -- links) are unreadable on several themes — pin to palette colors instead
    LazyButton = { bg = "one_bg2", fg = "light_grey" },
    LazyButtonActive = { bg = "blue", fg = "black" },
    LazyH1 = { bg = "blue", fg = "black" },

    -- Comment = { italic = true },
    -- ["@comment"] = { italic = true },
  },
}

M.nvdash = { load_on_startup = true }

-- :MasonInstallAll reads this list (mason registry names, not lspconfig names).
-- rustfmt comes from the system rust toolchain (pacman), so it is not listed.
M.mason = {
  pkgs = {
    -- lsp
    "asm-lsp",
    "bash-language-server",
    "basedpyright",
    "biome",
    "clangd",
    "css-lsp",
    "dockerfile-language-server",
    "gopls",
    "html-lsp",
    "json-lsp",
    "lua-language-server",
    "ruff",
    "rust-analyzer",
    "tailwindcss-language-server",
    "vtsls",
    "yaml-language-server",

    -- formatters
    "clang-format",
    "gofumpt",
    "goimports",
    "prettier",
    "shfmt",
    "stylua",

    -- dap
    "codelldb",
    "debugpy",
    "delve",
    "js-debug-adapter",
  },
}

return M
