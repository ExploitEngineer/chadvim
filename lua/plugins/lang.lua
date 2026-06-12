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
}
