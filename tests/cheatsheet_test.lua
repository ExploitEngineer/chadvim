-- Every :Command the cheatsheet advertises must exist once its plugin is
-- loaded. The cheatsheet is what you read when you forget a command; a dead
-- entry there sends you to an E492.
local T = dofile "tests/helpers.lua"
T.settle()

-- commands of lazy plugins without a cmd stub only exist after loading
local names = vim.tbl_keys(require("lazy.core.config").plugins)
pcall(require("lazy").load, { plugins = names, wait = true })

-- buffer-local commands that only exist inside the buffer they act on
local BUFFER_LOCAL = {
  CEShowTooltip = "compiler-explorer's asm output buffer",
  CEGotoLabel = "compiler-explorer's asm output buffer",
}

for section, entries in pairs(require("configs.cheatsheet").commands) do
  for _, entry in ipairs(entries) do
    local cmd = entry[2]:match "^:(%u[%w_]*)"
    if cmd and not BUFFER_LOCAL[cmd] then
      T.eq(vim.fn.exists(":" .. cmd), 2, ("%s: %s (%s)"):format(section, entry[2], entry[1]))
    end
  end
end

T.done()
