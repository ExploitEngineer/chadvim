-- Keymap audit: every mapping that runs an Ex command must name a command that
-- exists, and no mapping may still call a plugin this config removed. This is
-- the guard for every plugin swap: a dead key fails here, not in your hands.
local T = dofile "tests/helpers.lua"

-- Command prefixes of removed plugins. Each swap adds the one it removed.
local REMOVED = {}

T.settle()

-- open a real Lua file so buffer-local maps (LSP on attach, gitsigns) exist
vim.cmd.edit "lua/options.lua"
local attached = vim.wait(15000, function()
  return #vim.lsp.get_clients { bufnr = 0 } > 0 and vim.b.gitsigns_status_dict ~= nil
end, 50)
T.ok(attached, "lua_ls and gitsigns attached, so buffer-local maps are audited")
vim.wait(200) -- on_attach runs right after the client registers

local function check(lhs, mode, rhs, where, plugin)
  if type(rhs) ~= "string" then
    return
  end
  local cmd = rhs:match "^<[Cc][Mm][Dd]>%s*(%u[%w_]*)" or rhs:match "^:%s*(%u[%w_]*)"
  if cmd then
    if plugin and vim.fn.exists(":" .. cmd) ~= 2 then
      -- a `keys` stub loads its plugin on press, which defines the command
      require("lazy").load { plugins = { plugin }, wait = true }
    end
    T.eq(vim.fn.exists(":" .. cmd), 2, ("%s %s (%s) runs :%s"):format(mode, lhs, where, cmd))
  end
  for _, removed in ipairs(REMOVED) do
    T.ok(not rhs:find(removed, 1, true), ("%s %s (%s) still calls %s"):format(mode, lhs, where, removed))
  end
end

for _, mode in ipairs { "n", "v", "x", "i", "t", "o" } do
  for _, m in ipairs(vim.api.nvim_get_keymap(mode)) do
    check(m.lhs, mode, m.rhs, "global")
  end
  for _, m in ipairs(vim.api.nvim_buf_get_keymap(0, mode)) do
    check(m.lhs, mode, m.rhs, "buffer")
  end
end

-- lazy.nvim `keys` specs are stubs until their plugin loads, so their real
-- right-hand side never shows in nvim_get_keymap: audit the specs directly
local Plugin = require "lazy.core.plugin"
local Keys = require "lazy.core.handler.keys"
for name, plugin in pairs(require("lazy.core.config").plugins) do
  for _, key in pairs(Keys.resolve(Plugin.values(plugin, "keys", true))) do
    check(key.lhs, key.mode or "n", key.rhs, name, name)
  end
end

T.done()
