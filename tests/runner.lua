-- Loaded by tests/run.sh. Runs one test file and turns a Lua error into a
-- non-zero exit instead of leaving a headless Neovim waiting forever.
local file = vim.env.CHADVIM_TEST_FILE
local ok, err = xpcall(dofile, debug.traceback, file)
if not ok then
  io.stdout:write("ERROR: " .. tostring(err) .. "\n")
  io.stdout:flush()
  vim.cmd "cquit 2"
end
io.stdout:write("ERROR: " .. file .. " returned without calling T.done()\n")
io.stdout:flush()
vim.cmd "cquit 3"
