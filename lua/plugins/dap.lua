return {
  {
    "mfussenegger/nvim-dap",
    cmd = { "DapContinue", "DapToggleBreakpoint" },
    -- keys live in lua/mappings.lua (NvChad maps <leader>ds itself, so a
    -- `keys=` spec here would get partially clobbered)
    dependencies = {
      { "rcarriga/nvim-dap-ui", dependencies = { "nvim-neotest/nvim-nio" } },
      { "theHamsta/nvim-dap-virtual-text", opts = {} },
      "mfussenegger/nvim-dap-python",
      { "leoluz/nvim-dap-go", opts = {} }, -- delve adapter + go configs
    },
    config = function()
      require "configs.dap"
    end,
  },
}
