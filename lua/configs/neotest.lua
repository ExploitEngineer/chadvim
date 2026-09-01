-- Adapter modules are all callable: calling them returns the configured
-- adapter, so they must be invoked here rather than passed as bare modules.
require("neotest").setup {
  adapters = {
    require "neotest-golang" {},
    require "neotest-python" { dap = { justMyCode = false } },
    require "neotest-vitest",
    -- rustaceanvim owns rust-analyzer, and ships the cargo-test adapter with it
    require "rustaceanvim.neotest",
  },

  status = { virtual_text = true, signs = false }, -- signs would fight gitsigns in the sign column
  output = { open_on_run = false }, -- <leader>to opens it on demand instead
  quickfix = { enabled = false }, -- otherwise every run stomps the quickfix list

  icons = {
    passed = "",
    failed = "",
    running = "",
    skipped = "",
    unknown = "",
  },
}
