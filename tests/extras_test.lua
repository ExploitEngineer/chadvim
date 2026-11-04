-- devaslife's additions: snacks notifier, lazygit float and word highlights,
-- gitlinker, and mason-tool-installer. NvChad's UI keeps indent guides,
-- statuscolumn, dashboard and scrolling, so snacks must leave those off.
local T = dofile "tests/helpers.lua"
T.fake_clipboard()
T.settle()

local plugins = require("lazy.core.config").plugins
local Plugin = require "lazy.core.plugin"

-- snacks modules
local cfg = Snacks.config
for _, name in ipairs { "notifier", "lazygit", "words", "picker" } do
  T.eq(cfg[name] and cfg[name].enabled, true, "snacks." .. name .. " on")
end
for _, name in ipairs { "indent", "statuscolumn", "dashboard", "scroll" } do
  T.ok(not (cfg[name] and cfg[name].enabled), "snacks." .. name .. " off (NvChad owns it)")
end
local notify_src = debug.getinfo(vim.notify, "S").source or ""
T.ok(notify_src:find("snacks", 1, true) ~= nil, "vim.notify is the snacks notifier")

local function press(keys)
  vim.api.nvim_feedkeys(vim.keycode((keys:gsub("<leader>", vim.g.mapleader))), "mx", false)
end

-- <leader>sn: notification history in the picker
vim.notify "extras test notification"
press "<leader>sn"
T.ok(
  vim.wait(3000, function()
    return #Snacks.picker.get() > 0
  end, 20),
  "<leader>sn opens notification history"
)
for _, picker in ipairs(Snacks.picker.get()) do
  picker:close()
end

-- <leader>gg: lazygit in a snacks float
vim.cmd.edit "lua/options.lua"
press "<leader>gg"
local lazygit_win
T.ok(
  vim.wait(5000, function()
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      local buf = vim.api.nvim_win_get_buf(win)
      if vim.bo[buf].buftype == "terminal" and vim.api.nvim_win_get_config(win).relative ~= "" then
        lazygit_win = win
        return true
      end
    end
    return false
  end, 50),
  "<leader>gg opens lazygit in a floating terminal"
)
if lazygit_win then
  local job = vim.b[vim.api.nvim_win_get_buf(lazygit_win)].terminal_job_id
  if job then
    vim.fn.jobstop(job)
  end
  pcall(vim.api.nvim_win_close, lazygit_win, true)
end

-- gitlinker: :GitLink and <leader>gy in normal and visual mode
T.eq(vim.fn.exists ":GitLink", 2, ":GitLink exists")
for _, mode in ipairs { "n", "x" } do
  T.ok(vim.fn.maparg("<leader>gy", mode) ~= "", "<leader>gy mapped in mode " .. mode)
end

-- mason-tool-installer installs exactly chadrc's list, never auto-updates
local mti = Plugin.values(plugins["mason-tool-installer.nvim"], "opts", false)
T.eq(mti.ensure_installed, require("chadrc").mason.pkgs, "installs chadrc's mason list")
T.eq(mti.auto_update, false, "no auto-update")

T.done()
