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

  -- DAP adapter for Neovim's own Lua: debug this config with the setup above.
  -- Two instances are involved -- see the nlua block in lua/configs/dap.lua.
  {
    "jbyuki/one-small-step-for-vimkind",
    dependencies = "mfussenegger/nvim-dap",
    keys = {
      {
        "<leader>dL",
        function()
          require("osv").launch { port = 8086 }
        end,
        desc = "Launch Lua debug server",
      },
      {
        "<leader>dN",
        function()
          require("osv").run_this()
        end,
        desc = "Debug this Lua file",
      },
    },
  },
}
