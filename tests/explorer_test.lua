-- oil.nvim is the file explorer: directories open in it, the explorer keys
-- toggle it as a float, and claudecode's "add file" key works inside it.
local T = dofile "tests/helpers.lua"
T.settle()

T.eq(require("lazy.core.config").plugins["nvim-tree.lua"], nil, "nvim-tree is gone")

-- `nvim .` lands in oil (not netrw, not nvdash)
local child = vim
  .system({ "nvim", "--headless", "-c", "lua io.stdout:write(vim.bo.filetype)", "-c", "qa!", "." }, { text = true })
  :wait(60000)
T.eq(child.stdout, "oil", "nvim . opens oil")

-- :edit on a directory inside a session
vim.cmd.edit(vim.fn.getcwd())
T.eq(vim.bo.filetype, "oil", ":edit <dir> opens oil")
vim.cmd.enew()

local function float_ft()
  local cfg = vim.api.nvim_win_get_config(0)
  return cfg.relative ~= "" and vim.bo.filetype or nil
end

for _, lhs in ipairs { "<leader>e", "<C-n>" } do
  vim.cmd.edit "lua/options.lua"
  vim.api.nvim_feedkeys(vim.keycode((lhs:gsub("<leader>", vim.g.mapleader))), "mx", false)
  T.ok(
    vim.wait(3000, function()
      return float_ft() == "oil"
    end, 20),
    lhs .. " opens oil in a float"
  )
  T.eq(vim.api.nvim_buf_get_name(0):match "lua/$" ~= nil, true, lhs .. " starts at the current file's directory")
  T.eq(vim.fn.maparg("<leader>at", "n", false, true).buffer, 1, "<leader>at (add file to Claude) is mapped in oil")
  -- the same key closes it again
  vim.api.nvim_feedkeys(vim.keycode((lhs:gsub("<leader>", vim.g.mapleader))), "mx", false)
  T.ok(
    vim.wait(3000, function()
      return float_ft() == nil
    end, 20),
    lhs .. " again closes the float"
  )
end

T.done()
