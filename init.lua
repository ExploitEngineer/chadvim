-- tests point this at a throwaway dir (tests/run.sh) so they never compile
-- into the real cache that every normal start loads from
vim.g.base46_cache = vim.env.CHADVIM_BASE46_CACHE or vim.fn.stdpath "data" .. "/base46/"
vim.g.mapleader = " "

-- bootstrap lazy and all plugins
local lazypath = vim.fn.stdpath "data" .. "/lazy/lazy.nvim"

if not vim.uv.fs_stat(lazypath) then
  local repo = "https://github.com/folke/lazy.nvim.git"
  vim.fn.system { "git", "clone", "--filter=blob:none", repo, "--branch=stable", lazypath }
end

vim.opt.rtp:prepend(lazypath)

local lazy_config = require "configs.lazy"

-- load plugins
require("lazy").setup({
  {
    "NvChad/NvChad",
    lazy = false,
    branch = "v2.5",
    import = "nvchad.plugins",
  },

  { import = "plugins" },
}, lazy_config)

-- load theme, recompiling first if the cache is stale (see lua/theme_cache.lua)
require("theme_cache").load()

require "options"
require "autocmds"

vim.schedule(function()
  require "mappings"
end)
