-- This file needs to have same structure as nvconfig.lua
-- https://github.com/NvChad/ui/blob/v3.0/lua/nvconfig.lua

---@type ChadrcConfig
local M = {}

M.base46 = {
  theme = "ayu_dark",

  -- compile theme colors for these added plugins too (loaded in options.lua)
  integrations = { "dap", "diffview", "flash", "trouble", "todo", "grug_far" },

  -- base46 ships no lazy.nvim integration file; the Lazy groups sit in its
  -- defaults, where LazyButton's fg is chosen with
  --   lighten(light_grey, vim.o.bg == "dark" and 10 or -20)
  -- evaluated at *compile* time. base46 only emits `vim.o.bg = 'dark'` into the
  -- compiled cache, so a cache built while the terminal reported a light
  -- background freezes that fg at #2c2b31 against a #262431 button: a 1.06:1
  -- contrast ratio, i.e. an invisible button row. base46 also never defines
  -- LazyButtonActive at all. Pin both so the row survives any recompile.
  hl_override = {
    LazyButton = { bg = "one_bg2", fg = "white" },

    -- Comment = { italic = true },
    -- ["@comment"] = { italic = true },
  },

  -- hl_add, not hl_override: base46 only rewrites groups it already ships,
  -- and LazyButtonActive is not one of them
  hl_add = {
    LazyButtonActive = { bg = "blue", fg = "black", bold = true },
  },
}

M.nvdash = { load_on_startup = true }

-- :MasonInstallAll reads this list (mason registry names, not lspconfig names).
-- rustfmt comes from the system rust toolchain (pacman), so it is not listed.
-- zls is NOT here on purpose: mason only ships tagged zls, which won't run
-- against the nightly zig in use — a version-matched zls nightly lives at
-- ~/.local/bin/zls instead (see configs/lspconfig.lua for the re-match command).
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
