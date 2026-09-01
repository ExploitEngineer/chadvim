-- Overrides for NvChad's core plugins. Themed additions live in the sibling
-- files (editor, git, dap, lang, tools) — lazy.nvim imports every module here.

return {
  {
    "stevearc/conform.nvim",
    event = "BufWritePre", -- enables format on save
    opts = require "configs.conform",
  },

  -- the other half of the conform pair: linters for the filetypes whose LSP
  -- doesn't already carry one (see lua/configs/lint.lua for what's covered)
  {
    "mfussenegger/nvim-lint",
    event = "User FilePost",
    config = function()
      require "configs.lint"
    end,
    -- declared here rather than in configs/lint.lua so lazy registers the
    -- stub up front and the cheatsheet lists it before the plugin has loaded
    keys = {
      {
        "<leader>cl",
        function()
          require("lint").try_lint()
        end,
        desc = "Lint buffer",
      },
    },
  },

  -- lazydev registers its own nvim-cmp source; wire it in ahead of the rest so
  -- plugin module completions in lua/ outrank buffer words
  {
    "hrsh7th/nvim-cmp",
    opts = function(_, opts)
      opts.sources = opts.sources or {}
      for _, source in ipairs(opts.sources) do
        if source.name == "lazydev" then
          return opts -- change_detection re-runs this; don't stack duplicates
        end
      end
      table.insert(opts.sources, 1, { name = "lazydev", group_index = 0 })
      return opts
    end,
  },

  {
    "neovim/nvim-lspconfig",
    config = function()
      require "configs.lspconfig"
    end,
  },

  {
    "nvim-treesitter/nvim-treesitter",

    -- NvChad's spec still advertises master-branch commands (TSBufEnable,
    -- TSBufDisable, TSModuleInfo) that the main branch dropped. These are the
    -- ones that actually exist, plus NvChad's own TSInstallAll, so `:TSUpdate`
    -- and friends lazy-load the plugin instead of erroring with E492.
    cmd = { "TSInstall", "TSInstallFromGrammar", "TSInstallAll", "TSUpdate", "TSUninstall", "TSLog" },

    -- Replaces NvChad's `:TSUpdate | TSInstallAll`. Bare :TSUpdate updates
    -- *every installed* parser, and kulala.nvim compiles its own kulala_http
    -- parser into the shared site/parser dir. nvim-treesitter has no registry
    -- entry for it, so each plugin update logged
    -- `error: Parser not available for language "kulala_http"`.
    -- Scoping both calls to ensure_installed leaves foreign parsers alone.
    build = function()
      local opts = require("lazy.core.config").plugins["nvim-treesitter"].opts
      -- never fall through to nil here: update(nil) means "all installed",
      -- which is exactly the kulala_http case this build exists to avoid
      local langs = type(opts) == "table" and opts.ensure_installed or {}
      local ts = require "nvim-treesitter"
      ts.update(langs):wait(600000) -- refresh outdated parsers we asked for
      ts.install(langs):wait(600000) -- add any newly listed ones (skips installed)
    end,

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
        "zig",
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
        "json", -- also serves jsonc: no separate jsonc parser on the main branch
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
        -- no "http": kulala.nvim ships its own kulala_http parser and registers
        -- it for the http/rest filetypes, so the generic one never gets used
        "sql",
      },
    },
  },

  {
    "folke/which-key.nvim",
    -- Groups are generated from the same prefix table the cheatsheet sections
    -- on, so a new <leader> prefix is declared in exactly one place and the
    -- two views can't drift apart.
    opts = {
      spec = require("configs.cheatsheet").wk_spec(),
    },
  },
}
