-- Overrides for NvChad's core plugins. Themed additions live in the sibling
-- files (editor, git, dap, lang, tools) — lazy.nvim imports every module here.

return {
  {
    "stevearc/conform.nvim",
    event = "BufWritePre", -- enables format on save
    opts = require "configs.conform",
  },

  {
    "neovim/nvim-lspconfig",
    config = function()
      require "configs.lspconfig"
    end,
  },

  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      -- lazy.nvim's opts merge REPLACES lists, so NvChad's defaults
      -- (lua, luadoc, printf, vim, vimdoc) are re-included here
      ensure_installed = {
        "lua",
        "luadoc",
        "printf",
        "vim",
        "vimdoc",
        -- low-level
        "c",
        "cpp",
        "asm",
        "make",
        "cmake",
        "rust",
        "toml",
        -- scripting / backend
        "python",
        "go",
        "gomod",
        "gowork",
        "gosum",
        "bash",
        -- web
        "javascript",
        "typescript",
        "tsx",
        "html",
        "css",
        "scss",
        "json",
        "jsonc",
        "yaml",
        "graphql",
        -- misc
        "markdown",
        "markdown_inline",
        "regex",
        "query",
        "diff",
        "gitcommit",
        "git_rebase",
        "gitignore",
        "dockerfile",
        "http", -- kulala
        "sql",
      },
    },
  },

  {
    "folke/which-key.nvim",
    opts = {
      spec = {
        { "<leader>b", group = "buffer" },
        { "<leader>c", group = "code" },
        { "<leader>d", group = "debug" },
        { "<leader>f", group = "find" },
        { "<leader>g", group = "git" },
        { "<leader>gh", group = "hunks" },
        { "<leader>q", group = "session" },
        { "<leader>R", group = "rest" },
        { "<leader>s", group = "search" },
        { "<leader>u", group = "toggles" },
        { "<leader>w", group = "windows" },
        { "<leader>x", group = "diagnostics/quickfix" },
        { "gs", group = "surround" },
      },
    },
  },
}
