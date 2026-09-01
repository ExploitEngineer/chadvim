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

  -- xxd-backed hex view: :HexToggle round-trips the buffer through xxd, so
  -- edits in the hex pane write back to the real binary on :w
  {
    "RaafatTurki/hex.nvim",
    cmd = { "HexToggle", "HexDump", "HexAssemble" },
    opts = {},
    keys = {
      { "<leader>uh", "<cmd>HexToggle<CR>", desc = "Toggle hex view" },
    },
  },

  -- godbolt.org from inside the buffer: compiles the file (or the visual
  -- selection) remotely and opens the asm side by side, with source lines
  -- highlighted against the instructions they generated
  {
    "krady21/compiler-explorer.nvim",
    dependencies = "nvim-lua/plenary.nvim",
    cmd = {
      "CECompile",
      "CECompileLive",
      "CEFormat",
      "CEAddLibrary",
      "CELoadExample",
      "CEOpenWebsite",
      "CEDeleteCache",
      "CEShowTooltip",
      "CEGotoLabel",
    },
    opts = {
      line_match = { highlight = true, jump = false },
      open_qflist = true, -- compiler diagnostics land in the quickfix list

      -- Pinning a compiler per language skips the picker entirely on
      -- :CECompile. These ids are godbolt's, matched against the local
      -- toolchain so the asm shown is what this machine would actually
      -- produce; re-check them after a toolchain bump with
      --   curl -s "https://godbolt.org/api/compilers/c?fields=id,name"
      -- Note the id scheme differs by language: C prefixes with a `c`
      -- (cclang2210, cg162) where C++ does not (clang2210, g162).
      --
      -- Keys are godbolt's *language* ids, not Neovim filetypes, so C++ is
      -- "c++" and not "cpp". A key that matches no language is ignored in
      -- silence and you get the 900-entry picker back.
      languages = {
        c = { compiler = "cclang2210", compiler_flags = "-O2 -Wall -Wextra" }, -- local clang 22.1.8
        ["c++"] = { compiler = "clang2210", compiler_flags = "-O2 -Wall -Wextra" },
        rust = { compiler = "r1980", compiler_flags = "-C opt-level=2" }, -- local rustc 1.98.0
        zig = { compiler = "ztrunk", compiler_flags = "-O ReleaseFast" }, -- local zig is a 0.17 dev build
        go = { compiler = "gl1260" }, -- godbolt tops out at 1.26; local go is 1.27
      },
    },
    keys = {
      { "<leader>cc", "<cmd>CECompile<CR>", mode = { "n", "v" }, desc = "Compiler Explorer" },
      { "<leader>cC", "<cmd>CECompileLive<CR>", mode = { "n", "v" }, desc = "Compiler Explorer (live)" },
    },
  },
}
