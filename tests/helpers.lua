-- Assertion helpers for the headless tests. Run them with tests/run.sh, which
-- gives every test file its own throwaway base46 and HyDE cache dirs.
local T = { failures = {} }

function T.ok(cond, msg)
  if not cond then
    table.insert(T.failures, msg)
  end
end

function T.eq(actual, expected, msg)
  if not vim.deep_equal(actual, expected) then
    table.insert(T.failures, ("%s: expected %s, got %s"):format(msg, vim.inspect(expected), vim.inspect(actual)))
  end
end

-- A headless Neovim never fires UIEnter, and NvChad's `User FilePost` (which
-- lazy-loads half the plugins) waits on it. Fire it the way a UI would, then
-- let the scheduled work run: lua/mappings.lua and lazy's VeryLazy.
function T.settle()
  if not vim.g.ui_entered then
    vim.api.nvim_exec_autocmds("UIEnter", {})
  end
  vim.wait(5000, function()
    return vim.g.did_very_lazy == true
  end, 20)
  vim.wait(50) -- whatever those callbacks scheduled in turn
end

function T.done()
  for _, failure in ipairs(T.failures) do
    io.stdout:write("FAIL: " .. failure .. "\n")
  end
  io.stdout:flush()
  vim.cmd(#T.failures > 0 and "cquit 1" or "qall!")
end

return T
