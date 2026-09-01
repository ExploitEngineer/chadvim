require "nvchad.autocmds"

local autocmd = vim.api.nvim_create_autocmd

autocmd("TextYankPost", {
  desc = "Highlight on yank",
  callback = function()
    vim.hl.on_yank()
  end,
})

autocmd("BufReadPost", {
  desc = "Go to last cursor location when opening a buffer",
  callback = function(event)
    local buf = event.buf
    if vim.b[buf].last_loc_done or vim.bo[buf].filetype == "gitcommit" then
      return
    end
    vim.b[buf].last_loc_done = true
    local mark = vim.api.nvim_buf_get_mark(buf, '"')
    if mark[1] > 0 and mark[1] <= vim.api.nvim_buf_line_count(buf) then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

autocmd("FileType", {
  pattern = { "sql", "mysql", "plsql" },
  desc = "dadbod completion source for SQL buffers",
  callback = function()
    require("cmp").setup.buffer { sources = { { name = "vim-dadbod-completion" } } }
  end,
})

-- base46 only recompiles its highlight cache in the plugin's own `build` hook,
-- so editing M.base46 in chadrc (a new integration, an hl_override) changes
-- nothing until the next base46 update. That failure is silent: the compiled
-- file for the new integration simply never exists and options.lua's dofile
-- loop pcall-skips it. Recompile whenever chadrc is written instead.
autocmd("BufWritePost", {
  pattern = vim.fn.stdpath "config" .. "/lua/chadrc.lua",
  desc = "Recompile base46 highlights after a chadrc edit",
  callback = function()
    require("plenary.reload").reload_module "chadrc"
    require("plenary.reload").reload_module "nvconfig"
    require("base46").load_all_highlights()
    vim.notify "base46 highlights recompiled"
  end,
})
