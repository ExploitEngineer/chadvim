require "nvchad.options"

local o = vim.o

o.relativenumber = true
o.scrolloff = 4
o.sidescrolloff = 8
o.wrap = false

-- persistence.nvim needs globals/skiprtp/folds for full session restore
vim.opt.sessionoptions = { "buffers", "curdir", "tabpages", "winsize", "help", "globals", "skiprtp", "folds" }

-- consumed by conform's format_on_save (toggles: <leader>uf global, <leader>uF buffer)
vim.g.autoformat = true

-- mason.nvim is lazy-loaded on :Mason, which means its bin dir isn't on PATH
-- until then — prepend it so LSP/DAP binaries resolve from session start
vim.env.PATH = vim.fn.stdpath "data" .. "/mason/bin:" .. vim.env.PATH

-- load the extra base46 integrations compiled via chadrc (M.base46.integrations)
for _, integ in ipairs { "dap", "diffview", "flash", "trouble", "todo", "grug_far" } do
  pcall(dofile, vim.g.base46_cache .. integ)
end
