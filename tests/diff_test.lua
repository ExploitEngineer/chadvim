-- Diff review: codediff for whole-change review, the mini.diff overlay for
-- reading hunks in place, gitsigns for the gutter. diffview is gone.
local T = dofile "tests/helpers.lua"
T.settle()

T.eq(require("lazy.core.config").plugins["diffview.nvim"], nil, "diffview is gone")
T.eq(vim.fn.exists ":CodeDiff", 2, ":CodeDiff exists")

-- a repo with one committed 20-line file, line 15 then changed in the buffer
local repo = vim.fn.tempname()
vim.fn.mkdir(repo, "p")
local lines = {}
for i = 1, 20 do
  lines[i] = "line " .. i
end
vim.fn.writefile(lines, repo .. "/f.txt")
local function git(...)
  vim.fn.system { "git", "-C", repo, "-c", "user.name=t", "-c", "user.email=t@t", ... }
end
git("init", "--quiet")
git("add", "f.txt")
git("commit", "--quiet", "-m", "init")

vim.cmd.edit(repo .. "/f.txt")
vim.api.nvim_buf_set_lines(0, 14, 15, false, { "line 15 changed" })
local MiniDiff = require "mini.diff"
T.ok(
  vim.wait(5000, function()
    local data = MiniDiff.get_buf_data(0)
    return data ~= nil and data.hunks ~= nil and #data.hunks > 0
  end, 50),
  "mini.diff sees the hunk"
)

vim.api.nvim_win_set_cursor(0, { 1, 0 })
vim.api.nvim_feedkeys("]c", "xt", false)
T.eq(vim.api.nvim_win_get_cursor(0)[1], 15, "]c jumps to the hunk")

-- the gutter is gitsigns' alone: mini.diff draws no signs
local ns = vim.api.nvim_get_namespaces().MiniDiffViz
for _, mark in ipairs(vim.api.nvim_buf_get_extmarks(0, ns or -1, 0, -1, { details = true })) do
  T.eq(mark[4].sign_text, nil, "mini.diff draws no sign on line " .. (mark[2] + 1))
end

vim.api.nvim_feedkeys(vim.keycode((("<leader>ug"):gsub("<leader>", vim.g.mapleader))), "xt", false)
T.eq(MiniDiff.get_buf_data(0).overlay, true, "<leader>ug turns the overlay on")
vim.api.nvim_feedkeys(vim.keycode((("<leader>ug"):gsub("<leader>", vim.g.mapleader))), "xt", false)
T.eq(MiniDiff.get_buf_data(0).overlay, false, "<leader>ug turns it off again")

-- in native diff mode, ]c is Vim's own "next change", not mini.diff's hunk
local file_win = vim.api.nvim_get_current_win()
vim.cmd "vnew"
local other = vim.deepcopy(lines)
other[5] = "line 5 differs"
other[15] = "line 15 changed"
vim.api.nvim_buf_set_lines(0, 0, -1, false, other)
vim.cmd "diffthis"
vim.api.nvim_set_current_win(file_win)
vim.cmd "diffthis"
vim.api.nvim_win_set_cursor(0, { 1, 0 })
vim.api.nvim_feedkeys("]c", "xt", false)
T.eq(vim.api.nvim_win_get_cursor(0)[1], 5, "]c in diff mode goes to the next diff change")

T.done()
