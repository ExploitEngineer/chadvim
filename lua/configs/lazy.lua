return {
  defaults = { lazy = true },
  install = { colorscheme = { "nvchad" } },

  -- On Linux lazy.nvim leaves this nil, which means unlimited: `:Lazy update`
  -- forks a git fetch for all ~50 plugins at once, and each one does its own
  -- DNS lookup. A single upstream resolver drops queries under that burst and
  -- the whole update fails with `Could not resolve host: github.com`. Capping
  -- the fan-out costs a few seconds and makes updates actually finish.
  concurrency = 8,

  -- reload plugin specs on config save, but without the hit-enter notification
  change_detection = { enabled = true, notify = false },

  ui = {
    icons = {
      ft = "",
      lazy = "󰂠 ",
      loaded = "",
      not_loaded = "",
    },
  },

  performance = {
    rtp = {
      disabled_plugins = {
        "2html_plugin",
        "tohtml",
        "getscript",
        "getscriptPlugin",
        "gzip",
        "logipat",
        "netrw",
        "netrwPlugin",
        "netrwSettings",
        "netrwFileHandlers",
        "matchit",
        "tar",
        "tarPlugin",
        "rrhelper",
        "spellfile_plugin",
        "vimball",
        "vimballPlugin",
        "zip",
        "zipPlugin",
        "tutor",
        "rplugin",
        "syntax",
        "synmenu",
        "optwin",
        "compiler",
        "bugreport",
        "ftplugin",
      },
    },
  },
}
