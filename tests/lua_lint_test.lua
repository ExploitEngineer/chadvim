-- The config itself must be clean under lua_ls: no warnings or errors. A
-- standing warning (an undeclared global, an intentional override lua_ls
-- can't see as intentional) is noise that hides the next real one.
local T = dofile "tests/helpers.lua"
T.settle()

local FILES = { "lua/mappings.lua", "lua/configs/lspconfig.lua", "lua/plugins/editor.lua" }

-- lua_ls publishes early, before its settings and lazydev's libraries are in
-- (flagging `vim` itself), and again once its workspace has loaded. Track
-- both diagnostics and $/progress, and read only once both have gone quiet.
local last_change, busy = nil, false
vim.api.nvim_create_autocmd("DiagnosticChanged", {
  callback = function()
    last_change = vim.uv.now()
  end,
})
vim.api.nvim_create_autocmd("LspProgress", {
  callback = function(ev)
    local value = ev.data.params.value
    busy = value.kind ~= "end"
    last_change = vim.uv.now()
  end,
})

local function settled()
  return vim.wait(120000, function()
    return last_change ~= nil and not busy and vim.uv.now() - last_change > 3000
  end, 200)
end

for _, file in ipairs(FILES) do
  last_change = nil
  vim.cmd.edit(file)
  local buf = vim.api.nvim_get_current_buf()
  T.ok(settled(), file .. ": lua_ls diagnostics settled")
  for _, d in ipairs(vim.diagnostic.get(buf, { severity = { min = vim.diagnostic.severity.WARN } })) do
    T.ok(false, ("%s:%d %s"):format(file, d.lnum + 1, d.message))
  end
end

T.done()
