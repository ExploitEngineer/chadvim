return {
  {
    "mrcjkb/rustaceanvim",
    version = "^6",
    lazy = false, -- the plugin lazy-loads itself on rust filetypes
    -- rust-analyzer comes from mason (on PATH via options.lua); codelldb is
    -- auto-discovered from mason for :RustLsp debuggables
  },

  {
    "saecki/crates.nvim",
    event = "BufRead Cargo.toml",
    opts = {
      completion = { cmp = { enabled = true } },
    },
  },

  -- json/yaml schemas, required by configs/lspconfig.lua
  { "b0o/schemastore.nvim", lazy = true },

  -- On-demand LuaLS workspace libraries while editing this config. NvChad's
  -- lua_ls settings already pin $VIMRUNTIME, nvchad_types, lazy and luv; this
  -- adds every *other* installed plugin's lua/ dir the moment a buffer
  -- requires it, so `require "neotest"`, `require "dap"` etc. complete.
  {
    "folke/lazydev.nvim",
    ft = "lua",
    opts = {
      library = {
        { path = "${3rd}/luv/library", words = { "vim%.uv" } },
        { path = "lazy.nvim", words = { "LazySpec", "LazyPlugin" } },
        -- NvChad's own runtime: makes require "nvchad.term" / "nvchad.tabufline"
        -- in lua/mappings.lua resolve, and ---@type ChadrcConfig type-check
        { path = "ui", words = { "nvchad", "ChadrcConfig" } },
        { path = "base46", words = { "base46" } },
      },
    },
  },
}
