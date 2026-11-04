-- blink.cmp is the completion engine: nvim-cmp and its sources are gone, and
-- every source the old setup had (lsp, path, snippets, buffer, lazydev on
-- Lua, dadbod on SQL) is wired into blink.
local T = dofile "tests/helpers.lua"
T.settle()

local plugins = require("lazy.core.config").plugins
for _, name in ipairs {
  "nvim-cmp",
  "LuaSnip",
  "cmp_luasnip",
  "cmp-nvim-lsp",
  "cmp-nvim-lua",
  "cmp-buffer",
  "cmp-async-path",
} do
  T.eq(plugins[name], nil, name .. " is gone")
end

local cfg = require "blink.cmp.config"
for _, source in ipairs { "lsp", "path", "snippets", "buffer" } do
  T.ok(vim.list_contains(cfg.sources.default, source), "default sources include " .. source)
end
local function per_ft(ft)
  local sources = cfg.sources.per_filetype[ft]
  return type(sources) == "table" and sources or {}
end
T.ok(vim.list_contains(per_ft "lua", "lazydev"), "lazydev completes in Lua")
T.ok(vim.list_contains(per_ft "sql", "dadbod"), "dadbod completes in SQL")
-- blink wraps these per mode (insert/cmdline/term); outside the cmdline and
-- terminal the wrapper returns the insert-mode value
local preselect = cfg.completion.list.selection.preselect
if type(preselect) == "function" then
  preselect = preselect()
end
T.eq(preselect, false, "nothing preselected")

-- The prebuilt Rust matcher is in place (else blink falls back to Lua with a
-- warning). Whether typing opens the menu is checked in a real UI: with no
-- UI attached (headless) blink produces no items at all.
T.ok(
  vim.wait(3000, function()
    return require("blink.cmp.fuzzy").implementation_type == "rust"
  end, 50),
  "the prebuilt Rust matcher is in use"
)

-- crates.nvim completes through its in-process LSP, not an nvim-cmp source
T.eq(
  require("lazy.core.plugin").values(plugins["crates.nvim"], "opts", false).completion,
  nil,
  "crates has no cmp source"
)

-- auto-pairs: mini.pairs, not nvim-autopairs
T.eq(plugins["nvim-autopairs"], nil, "nvim-autopairs is gone")
vim.cmd.enew()
vim.api.nvim_feedkeys(vim.keycode "i(<Esc>", "xt", false)
T.eq(vim.api.nvim_get_current_line(), "()", "typing ( inserts ()")

-- its insert-mode maps stay out of the cheatsheet, like nvim-autopairs' did
local sections = vim.tbl_keys(require("configs.cheatsheet").organize_mappings())
for _, junk in ipairs { "Open", "Close", "Closeopen", "MiniPairs" } do
  T.ok(not vim.list_contains(sections, junk), "no cheatsheet section " .. junk)
end

T.done()
