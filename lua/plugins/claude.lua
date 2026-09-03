-- Replaces greggh/claude-code.nvim, which was only a terminal toggle plus a
-- file-reload autocmd: no way to see an edit before it landed, and unmaintained
-- since February 2026.
--
-- This one speaks the same MCP-over-WebSocket protocol as Anthropic's official
-- VS Code extension. It writes ~/.claude/ide/<port>.lock and the `claude` CLI
-- auto-discovers Neovim exactly as it discovers VS Code, so edits arrive here
-- as real buffers to review before they touch disk.
return {
  "coder/claudecode.nvim",
  -- No snacks.nvim: the README lists it, but every reference to it in the
  -- plugin is pcall-guarded. The terminal falls back to the builtin one and
  -- the tree integration reads NvimTree natively, so nothing here needs it.
  -- Keeping it out avoids its dashboard, statuscolumn, picker and notifier
  -- all overlapping NvChad's own UI.

  cmd = {
    "ClaudeCode",
    "ClaudeCodeFocus",
    "ClaudeCodeSelectModel",
    "ClaudeCodeAdd",
    "ClaudeCodeSend",
    "ClaudeCodeTreeAdd",
    "ClaudeCodeStatus",
    "ClaudeCodeStart",
    "ClaudeCodeStop",
    "ClaudeCodeOpen",
    "ClaudeCodeClose",
    "ClaudeCodeDiffAccept",
    "ClaudeCodeDiffDeny",
    "ClaudeCodeCloseAllDiffs",
  },

  opts = {
    terminal = {
      -- snacks.nvim is listed as a requirement but is optional, and this
      -- config deliberately avoids it: its dashboard, statuscolumn, picker and
      -- notifier all overlap NvChad's own UI. "native" is the builtin terminal.
      provider = "native",
      split_side = "right",
      split_width_percentage = 0.35,
    },

    diff_opts = {
      -- "unified" is the VS Code-style single buffer with deletions struck
      -- through in red and additions in green, interleaved in the real code,
      -- rather than the two-pane "vertical" default. Needs nvim >= 0.9.
      layout = "unified",
      -- NOT open_in_new_tab: a diff on its own tab page is invisible from the
      -- tab you are looking at, and NvChad's tabufline only hints at a second
      -- tab, so a review can sit there unnoticed while Claude waits on it.
      -- In the current tab it lands in front of you.
      open_in_new_tab = false,
      keep_terminal_focus = false, -- land the cursor in the diff, ready to review
    },
  },

  keys = {
    { "<leader>ac", "<cmd>ClaudeCode<CR>", desc = "Toggle Claude" },
    { "<leader>af", "<cmd>ClaudeCodeFocus<CR>", desc = "Focus Claude" },
    { "<leader>ab", "<cmd>ClaudeCodeAdd %<CR>", desc = "Add current buffer" },
    { "<leader>at", "<cmd>ClaudeCodeTreeAdd<CR>", desc = "Add file from tree", ft = "NvimTree" },
    { "<leader>as", "<cmd>ClaudeCodeSend<CR>", mode = "v", desc = "Send selection" },
    { "<leader>am", "<cmd>ClaudeCodeSelectModel<CR>", desc = "Select model" },
    { "<leader>ar", "<cmd>ClaudeCode --resume<CR>", desc = "Resume session" },
    { "<leader>aa", "<cmd>ClaudeCodeDiffAccept<CR>", desc = "Accept diff" },
    { "<leader>ad", "<cmd>ClaudeCodeDiffDeny<CR>", desc = "Reject diff" },
    { "<leader>aq", "<cmd>ClaudeCodeCloseAllDiffs<CR>", desc = "Close all diffs" },
    { "<leader>aS", "<cmd>ClaudeCodeStatus<CR>", desc = "Server status" },
  },
}
