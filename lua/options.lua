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

-- load the extra base46 integrations compiled via chadrc. Read back off
-- nvconfig rather than repeating the list: the two drifting apart is a
-- compiled-but-never-loaded highlight file, which fails silently.
for _, integ in ipairs(require("nvconfig").base46.integrations) do
  pcall(dofile, vim.g.base46_cache .. integ)
end

-- nvim-lint's BufWritePost hook honours this, mirroring vim.g.autoformat above
vim.g.autolint = true

-- swap in the cheatsheet's mapping collector (see configs/cheatsheet.lua for
-- what NvChad's own one gets wrong against these descs)
require("configs.cheatsheet").setup()
