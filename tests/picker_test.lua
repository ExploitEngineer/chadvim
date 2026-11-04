-- Every search key kept its letters and now opens the snacks picker.
local T = dofile "tests/helpers.lua"
T.settle()

T.eq(require("lazy.core.config").plugins["telescope.nvim"], nil, "telescope is gone")
local select_src = debug.getinfo(vim.ui.select, "S").source or ""
T.ok(select_src:find("snacks", 1, true) ~= nil, "vim.ui.select is the snacks picker (was " .. select_src .. ")")

vim.cmd.edit "lua/options.lua"
T.settle()

local function close_all()
  for _, picker in ipairs(Snacks.picker.get()) do
    picker:close()
  end
  vim.wait(100)
end

local KEYS = {
  "<leader><space>",
  "<leader>ff",
  "<leader>fa",
  "<leader>/",
  "<leader>sg",
  "<leader>fw",
  "<leader>sw",
  "<leader>,",
  "<leader>fb",
  "<leader>:",
  "<leader>sb",
  "<leader>fz",
  "<leader>sk",
  "<leader>sh",
  "<leader>fh",
  "<leader>ma",
  "<leader>fo",
  "<leader>cm",
}

local function press(lhs)
  close_all()
  vim.api.nvim_feedkeys(vim.keycode((lhs:gsub("<leader>", vim.g.mapleader))), "mx", false)
  local opened = vim.wait(3000, function()
    return #Snacks.picker.get() > 0
  end, 20)
  T.ok(opened, lhs .. " opens a snacks picker")
end

for _, lhs in ipairs(KEYS) do
  press(lhs)
end

-- snacks closes a picker that finds nothing, and this repo may be clean and
-- has no TODOs: give git status and the todo pickers a project that has both
local project = vim.fn.tempname()
vim.fn.mkdir(project, "p")
vim.fn.writefile({ "-- TODO: tidy this", "-- FIXME: and this" }, project .. "/todo.lua")
vim.fn.system { "git", "-C", project, "init", "--quiet" }
vim.cmd.cd(project)
press "<leader>gt"
press "<leader>st"
press "<leader>sT"
press "<leader>sR" -- resume: the todo picker above gives it something to resume
close_all()

T.eq(vim.fn.maparg("<leader>pt", "n"), "", "<leader>pt (NvChad term picker, no snacks equivalent) is gone")

T.done()
