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

-- Claude writes files from outside this Neovim instance. Its Edit tool goes
-- through the diff, but the shell commands it runs (gofmt, codegen, a build
-- that rewrites a file) do not, so an open buffer keeps showing stale content.
-- 'autoread' alone is not enough: it only re-reads when Neovim happens to
-- check, and it never checks while the cursor sits in a terminal buffer, which
-- is exactly where you are while Claude works.
local function checktime()
  -- :checktime throws E11 from the cmdline window and is pointless mid-command
  if vim.fn.getcmdwintype() ~= "" or vim.fn.mode():find "^c" then
    return
  end
  pcall(vim.cmd, "checktime")
end

autocmd({ "FocusGained", "BufEnter", "TermLeave", "TermClose" }, {
  group = vim.api.nvim_create_augroup("reload_changed_files", { clear = true }),
  desc = "Re-read buffers whose file changed on disk",
  callback = checktime,
})

autocmd("User", {
  pattern = "ClaudeCodeDiffClosed",
  desc = "Re-read the file the instant a Claude diff is accepted or rejected",
  callback = checktime,
})

-- ...and poll while Claude is connected, so a file it rewrites through a shell
-- command appears in the buffer without waiting for a window switch. Gated on
-- the connection so it costs nothing the rest of the time.
local reload_poll = vim.uv.new_timer()
reload_poll:start(
  2000,
  2000,
  vim.schedule_wrap(function()
    local cc = package.loaded["claudecode"]
    if cc and cc.is_claude_connected and cc.is_claude_connected() then
      checktime()
    end
  end)
)
