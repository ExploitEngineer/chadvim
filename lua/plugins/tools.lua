return {
  {
    "mistweaverco/kulala.nvim",
    ft = { "http", "rest" },
    opts = { global_keymaps = false },
    keys = {
      {
        "<leader>Rs",
        function()
          require("kulala").run()
        end,
        desc = "Send request",
        ft = { "http", "rest" },
      },
      {
        "<leader>Ra",
        function()
          require("kulala").run_all()
        end,
        desc = "Send all requests",
        ft = { "http", "rest" },
      },
      {
        "<leader>Rr",
        function()
          require("kulala").replay()
        end,
        desc = "Replay last request",
        ft = { "http", "rest" },
      },
      {
        "<leader>Ri",
        function()
          require("kulala").inspect()
        end,
        desc = "Inspect request",
        ft = { "http", "rest" },
      },
      {
        "<leader>Rc",
        function()
          require("kulala").copy()
        end,
        desc = "Copy as cURL",
        ft = { "http", "rest" },
      },
      {
        "<leader>Rn",
        function()
          require("kulala").jump_next()
        end,
        desc = "Next request",
        ft = { "http", "rest" },
      },
      {
        "<leader>Rp",
        function()
          require("kulala").jump_prev()
        end,
        desc = "Prev request",
        ft = { "http", "rest" },
      },
      {
        "<leader>Rq",
        function()
          require("kulala").close()
        end,
        desc = "Close UI",
        ft = { "http", "rest" },
      },
      {
        "<leader>Rt",
        function()
          require("kulala").toggle_view()
        end,
        desc = "Toggle headers/body",
        ft = { "http", "rest" },
      },
      {
        "<leader>Rb",
        function()
          require("kulala").scratchpad()
        end,
        desc = "Open scratchpad",
      },
    },
  },

  {
    "kristijanhusak/vim-dadbod-ui",
    cmd = { "DBUI", "DBUIToggle", "DBUIAddConnection", "DBUIFindBuffer" },
    dependencies = {
      { "tpope/vim-dadbod", lazy = true },
      { "kristijanhusak/vim-dadbod-completion", ft = { "sql", "mysql", "plsql" }, lazy = true },
    },
    init = function()
      vim.g.db_ui_use_nerd_fonts = 1
    end,
    -- <leader>D toggle lives in lua/mappings.lua; the sql cmp source hook in
    -- lua/autocmds.lua
  },
}
