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
