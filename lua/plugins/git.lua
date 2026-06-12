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

  {
    "sindrets/diffview.nvim",
    cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewFileHistory" },
    keys = {
      { "<leader>gd", "<cmd>DiffviewOpen<CR>", desc = "Diffview" },
      { "<leader>gf", "<cmd>DiffviewFileHistory %<CR>", desc = "File history (current file)" },
      { "<leader>gF", "<cmd>DiffviewFileHistory<CR>", desc = "File history (repo)" },
    },
  },

  -- lazygit needs no plugin: <leader>gg opens it in an NvChad floating term
  -- (see lua/mappings.lua)
}
