-- Completion: blink.cmp in place of NvChad's nvim-cmp stack.
return {
  -- NvChad's completion stack. LuaSnip goes with it: blink expands snippets
  -- with Neovim's own vim.snippet and reads friendly-snippets directly.
  { "hrsh7th/nvim-cmp", enabled = false },
  { "L3MON4D3/LuaSnip", enabled = false },
  { "windwp/nvim-autopairs", enabled = false }, -- mini.pairs below

  -- ( inserts (), and the same for brackets and quotes
  { "nvim-mini/mini.pairs", event = "InsertEnter", opts = {} },

  {
    "saghen/blink.cmp",
    version = "1.*", -- release tags ship the prebuilt fuzzy matcher
    -- Fetch that matcher at install/update time. Left to blink, it downloads
    -- on the first InsertEnter of some later session, and quitting before it
    -- finishes leaves a half-written library and Lua fallback matching.
    build = function()
      local done = false
      require("blink.cmp.fuzzy.download").ensure_downloaded(function()
        done = true
      end)
      vim.wait(300000, function()
        return done
      end, 100)
    end,
    event = { "InsertEnter", "CmdlineEnter" },
    dependencies = { "rafamadriz/friendly-snippets" },
    opts = {
      -- Enter accepts, Tab/S-Tab walk the list (and snippet placeholders),
      -- the same hands as NvChad's cmp setup
      keymap = {
        preset = "enter",
        ["<Tab>"] = { "select_next", "snippet_forward", "fallback" },
        ["<S-Tab>"] = { "select_prev", "snippet_backward", "fallback" },
      },
      completion = {
        -- nothing selected until asked, so Enter on an open menu is a newline
        list = { selection = { preselect = false, auto_insert = true } },
        documentation = { auto_show = true, auto_show_delay_ms = 200 },
      },
      sources = {
        default = { "lsp", "path", "snippets", "buffer" },
        per_filetype = {
          lua = { inherit_defaults = true, "lazydev" },
          sql = { inherit_defaults = true, "dadbod" },
          mysql = { inherit_defaults = true, "dadbod" },
          plsql = { inherit_defaults = true, "dadbod" },
        },
        providers = {
          -- plugin module completions in lua/ outrank buffer words
          lazydev = { name = "LazyDev", module = "lazydev.integrations.blink", score_offset = 100 },
          dadbod = { name = "Dadbod", module = "vim_dadbod_completion.blink" },
        },
      },
    },
  },
}
