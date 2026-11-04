-- Copying file references for agent prompts, and devaslife's editor
-- behaviours that were missing.
local T = dofile "tests/helpers.lua"
local clip = T.fake_clipboard()
T.settle()

local A = require "utils.agent_paths"
vim.cmd.edit "lua/options.lua"
local cwd = vim.fn.getcwd()

T.eq(A.relative_ref(0, 12), "lua/options.lua#L12", "relative, one line")
T.eq(A.relative_ref(0, 12, 20), "lua/options.lua#L12-L20", "relative, a range")
T.eq(A.relative_ref(0, 20, 12), "lua/options.lua#L12-L20", "a backwards range is ordered")
T.eq(A.relative_ref(0, 7, 7), "lua/options.lua#L7", "a one-line range is one line")
T.eq(A.absolute_ref(0, 3), cwd .. "/lua/options.lua#L3", "absolute")

local block = vim.split(A.code_block(0, 1, 2), "\n")
local file_lines = vim.api.nvim_buf_get_lines(0, 0, 2, false)
T.eq(block[1], "```lua lua/options.lua#L1-L2", "code block fence carries filetype and ref")
T.eq({ block[2], block[3] }, file_lines, "code block body is the lines verbatim")
T.eq(block[4], "```", "code block closes")

-- a file outside the cwd keeps its absolute path; a scratch buffer has none
vim.cmd.edit "/etc/hostname"
T.eq(A.relative_ref(0, 1), "/etc/hostname#L1", "outside the cwd: absolute")
vim.cmd.enew()
T.eq(A.relative_ref(0, 1), nil, "no file, no reference")

-- the keys copy to the clipboard
local function press(keys)
  vim.api.nvim_feedkeys(vim.keycode((keys:gsub("<leader>", vim.g.mapleader))), "xt", false)
end
local function copied()
  return clip["+"] and table.concat(clip["+"][1], "\n")
end
vim.cmd.edit "lua/options.lua"
vim.api.nvim_win_set_cursor(0, { 5, 0 })
press "<leader>yf"
T.eq(copied(), "lua/options.lua#L5", "<leader>yf copies the relative ref")
press "<leader>yp"
T.eq(copied(), cwd .. "/lua/options.lua#L5", "<leader>yp copies the absolute ref")
press "Vj<leader>yf"
T.eq(copied(), "lua/options.lua#L5-L6", "<leader>yf on a selection copies its range")
vim.api.nvim_win_set_cursor(0, { 5, 0 })
press "Vj<leader>yc"
T.eq(vim.split(copied() or "", "\n")[1], "```lua lua/options.lua#L5-L6", "<leader>yc copies a code block")

-- editor behaviours
T.eq(vim.o.winborder, "rounded", "floats have rounded borders")
local first = vim.api.nvim_get_current_win()
vim.cmd.split()
vim.cmd "doautocmd WinEnter"
T.eq(vim.wo[first].cursorline, false, "the inactive window has no cursorline")
T.eq(vim.wo.cursorline, true, "the active window has its cursorline")

T.done()
