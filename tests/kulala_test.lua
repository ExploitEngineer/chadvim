-- kulala.nvim ships its own lazy spec (kulala.nvim/lazy.lua) that adds
-- SessionLoadPost and VimLeavePre load events. Loading kulala there runs its
-- tree-sitter grammar fetch on every quit and every :restart; the quit's fetch
-- outlives Neovim, the restart's fetch collides with it on git's shallow.lock,
-- and the new Neovim opens on a "Press ENTER" error. kulala must load for
-- http/rest buffers only.
local T = dofile "tests/helpers.lua"
T.settle()

local kulala = require("lazy.core.config").plugins["kulala.nvim"]
local events = require("lazy.core.plugin").values(kulala, "event", true)
T.ok(not vim.list_contains(events, "SessionLoadPost"), "kulala does not load on SessionLoadPost")
T.ok(not vim.list_contains(events, "VimLeavePre"), "kulala does not load on VimLeavePre")
T.eq(require("lazy.core.plugin").values(kulala, "ft", true), { "http", "rest" }, "kulala loads for http/rest")

vim.api.nvim_exec_autocmds("SessionLoadPost", {})
vim.api.nvim_exec_autocmds("VimLeavePre", {})
T.eq(kulala._.loaded, nil, "firing both events leaves kulala unloaded")

T.done()
