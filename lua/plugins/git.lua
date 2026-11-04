return {
  {
    "lewis6991/gitsigns.nvim",
    -- extend NvChad's opts (keeps its signs + base46 highlights) with keymaps
    opts = function(_, opts)
      opts.on_attach = function(bufnr)
        local gs = require "gitsigns"
        local function bmap(mode, l, r, desc)
          vim.keymap.set(mode, l, r, { buffer = bufnr, desc = desc })
        end

        bmap("n", "]h", function()
          gs.nav_hunk "next"
        end, "Next hunk")
        bmap("n", "[h", function()
          gs.nav_hunk "prev"
        end, "Prev hunk")
        bmap({ "n", "v" }, "<leader>ghs", "<cmd>Gitsigns stage_hunk<CR>", "Stage hunk")
        bmap({ "n", "v" }, "<leader>ghr", "<cmd>Gitsigns reset_hunk<CR>", "Reset hunk")
        bmap("n", "<leader>ghS", gs.stage_buffer, "Stage buffer")
        bmap("n", "<leader>ghR", gs.reset_buffer, "Reset buffer")
        bmap("n", "<leader>ghp", gs.preview_hunk_inline, "Preview hunk inline")
        bmap("n", "<leader>gb", function()
          gs.blame_line()
        end, "Blame line")
        bmap("n", "<leader>ghb", function()
          gs.blame_line { full = true }
        end, "Blame line (full)")
        bmap("n", "<leader>ghd", gs.diffthis, "Diff this")
        bmap({ "o", "x" }, "ih", gs.select_hunk, "Select hunk")
      end
      return opts
    end,
  },

  -- Whole-change review: a VS Code style side-by-side diff with a file
  -- explorer, and file/repo history. Same keys diffview had.
  {
    "esmuellert/codediff.nvim",
    cmd = "CodeDiff",
    -- Its prebuilt diff library and file watcher otherwise download on first
    -- use, the watcher synchronously: the first <leader>gd freezes the UI for
    -- as long as the download takes. Fetch both at install/update instead.
    -- The watcher installer is internal API, hence the pcall: if an update
    -- moves it, codediff falls back to downloading on first use.
    build = function()
      vim.cmd "CodeDiff install"
      local done = false
      local ok = pcall(function()
        require("codediff.core.installer.watcher").ensure(function()
          done = true
        end)
      end)
      vim.wait(300000, function()
        return done or not ok
      end, 100)
    end,
    opts = {},
    keys = {
      { "<leader>gd", "<cmd>CodeDiff<CR>", desc = "Diff view (all changes)" },
      { "<leader>gf", "<cmd>CodeDiff history %<CR>", desc = "File history (current file)" },
      { "<leader>gF", "<cmd>CodeDiff history<CR>", desc = "File history (repo)" },
    },
  },

  -- In-place review: the overlay shows each whole hunk (old above new, as in
  -- `git diff`) inside the buffer. devaslife's fork adds that hunk grouping;
  -- upstream nvim-mini/mini.diff is the fallback if the branch disappears.
  -- gitsigns keeps the sign column; mini.diff only tints line numbers.
  {
    "craftzdog/mini.diff",
    branch = "feat/grouping",
    event = "User FilePost",
    keys = {
      {
        "<leader>ug",
        function()
          require("mini.diff").toggle_overlay(0)
        end,
        desc = "Toggle diff overlay",
      },
      -- ]c / [c as devaslife has them, except in diff mode (codediff, a
      -- :diffthis), where they stay Vim's own next/previous change
      {
        "]c",
        function()
          if vim.wo.diff then
            vim.cmd.normal { vim.v.count1 .. "]c", bang = true }
          else
            require("mini.diff").goto_hunk("next", { n_times = vim.v.count1 })
          end
        end,
        desc = "Next hunk",
      },
      {
        "[c",
        function()
          if vim.wo.diff then
            vim.cmd.normal { vim.v.count1 .. "[c", bang = true }
          else
            require("mini.diff").goto_hunk("prev", { n_times = vim.v.count1 })
          end
        end,
        desc = "Prev hunk",
      },
    },
    opts = {
      view = { overlay_style = "hunk" },
      -- its defaults would shadow gitsigns' ]h/[h and staging, and gh/gH
      mappings = {
        apply = "",
        reset = "",
        textobject = "",
        goto_first = "",
        goto_prev = "",
        goto_next = "",
        goto_last = "",
      },
    },
  },

  -- lazygit needs no plugin: <leader>gg opens it in an NvChad floating term
  -- (see lua/mappings.lua),

  -- GitHub issues/PRs as buffers, backed by the same `gh` CLI already set up.
  -- Review comments become virtual text on the diff; `gh auth` provides creds.
  {
    "pwntester/octo.nvim",
    cmd = "Octo",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "folke/snacks.nvim",
      "nvim-tree/nvim-web-devicons",
    },
    opts = {
      picker = "snacks",
      -- the classic `gh` token has no read:project scope; silence the nag
      suppress_missing_scope = { projects_v2 = true },
    },
    keys = {
      { "<leader>go", "<cmd>Octo<CR>", desc = "Octo" },
      { "<leader>gi", "<cmd>Octo issue list<CR>", desc = "Issues (Octo)" },
      { "<leader>gp", "<cmd>Octo pr list<CR>", desc = "Pull requests (Octo)" },
      { "<leader>gv", "<cmd>Octo review start<CR>", desc = "Start PR review (Octo)" },
    },
  },
}
