-- LazyVim-hybrid mappings on top of NvChad defaults.
--
-- This file runs (via vim.schedule in init.lua) AFTER lazy.nvim setup, so
-- nvchad.mappings would clobber plugin `keys=` specs sharing the same LHS.
-- Colliding plugin keys (harpoon, dap, dbui) therefore live here as require()
-- closures — requiring a lazy plugin's module still triggers its load.

require "nvchad.mappings"

local map = vim.keymap.set
local del = vim.keymap.del

-- ───────────────────── NvChad defaults vs LazyVim muscle memory ──────────
pcall(del, "n", "<leader>h") -- horizontal term → harpoon (<A-h> term toggle remains)
pcall(del, "n", "<leader>ds") -- diagnostic loclist → frees <leader>d* for dap
pcall(del, "v", "<leader>/") -- comment → native gc
map("n", "<leader>e", "<cmd>NvimTreeToggle<CR>", { desc = "Explorer toggle" }) -- was NvimTreeFocus
map("n", "<leader>/", "<cmd>Telescope live_grep<CR>", { desc = "Grep" }) -- was comment

-- ───────────────────── buffers (tabufline) ───────────────────────────────
map("n", "<S-h>", function()
  require("nvchad.tabufline").prev()
end, { desc = "Prev buffer" })

map("n", "<S-l>", function()
  require("nvchad.tabufline").next()
end, { desc = "Next buffer" })

map("n", "<leader>bd", function()
  require("nvchad.tabufline").close_buffer()
end, { desc = "Delete buffer" })

map("n", "<leader>bo", function()
  require("nvchad.tabufline").closeAllBufs(false)
end, { desc = "Delete other buffers" })

-- ───────────────────── pickers (telescope) ───────────────────────────────
map("n", "<leader><space>", "<cmd>Telescope find_files<CR>", { desc = "Find files" })
map("n", "<leader>,", "<cmd>Telescope buffers sort_mru=true<CR>", { desc = "Buffers" })
map("n", "<leader>:", "<cmd>Telescope command_history<CR>", { desc = "Command history" })
map("n", "<leader>sg", "<cmd>Telescope live_grep<CR>", { desc = "Grep" })
map("n", "<leader>sw", "<cmd>Telescope grep_string<CR>", { desc = "Grep word under cursor" })
map("n", "<leader>sb", "<cmd>Telescope current_buffer_fuzzy_find<CR>", { desc = "Buffer lines" })
map("n", "<leader>sk", "<cmd>Telescope keymaps<CR>", { desc = "Keymaps" })
map("n", "<leader>sh", "<cmd>Telescope help_tags<CR>", { desc = "Help pages" })
map("n", "<leader>sR", "<cmd>Telescope resume<CR>", { desc = "Resume last picker" })

-- ───────────────────── diagnostics ───────────────────────────────────────
map("n", "<leader>cd", vim.diagnostic.open_float, { desc = "Line diagnostics" })

local function diag_jump(count, severity)
  return function()
    vim.diagnostic.jump { count = count, float = true, severity = severity and vim.diagnostic.severity[severity] }
  end
end
map("n", "]d", diag_jump(1), { desc = "Next diagnostic" })
map("n", "[d", diag_jump(-1), { desc = "Prev diagnostic" })
map("n", "]e", diag_jump(1, "ERROR"), { desc = "Next error" })
map("n", "[e", diag_jump(-1, "ERROR"), { desc = "Prev error" })
map("n", "]w", diag_jump(1, "WARN"), { desc = "Next warning" })
map("n", "[w", diag_jump(-1, "WARN"), { desc = "Prev warning" })

-- ───────────────────── editing ───────────────────────────────────────────
map("n", "<A-j>", "<cmd>execute 'move .+' . v:count1<CR>==", { desc = "Move line down" })
map("n", "<A-k>", "<cmd>execute 'move .-' . (v:count1 + 1)<CR>==", { desc = "Move line up" })
map("i", "<A-j>", "<Esc><cmd>m .+1<CR>==gi", { desc = "Move line down" })
map("i", "<A-k>", "<Esc><cmd>m .-2<CR>==gi", { desc = "Move line up" })
map("v", "<A-j>", ":<C-u>execute \"'<,'>move '>+\" . v:count1<CR>gv=gv", { desc = "Move selection down" })
map("v", "<A-k>", ":<C-u>execute \"'<,'>move '<-\" . (v:count1 + 1)<CR>gv=gv", { desc = "Move selection up" })

-- n/N always search forward/backward respectively, and open folds
map("n", "n", "'Nn'[v:searchforward].'zv'", { expr = true, desc = "Next search result" })
map({ "x", "o" }, "n", "'Nn'[v:searchforward]", { expr = true, desc = "Next search result" })
map("n", "N", "'nN'[v:searchforward].'zv'", { expr = true, desc = "Prev search result" })
map({ "x", "o" }, "N", "'nN'[v:searchforward]", { expr = true, desc = "Prev search result" })

map({ "n", "v" }, "<leader>cf", function()
  require("conform").format { lsp_format = "fallback" }
end, { desc = "Format" })

-- ───────────────────── windows ───────────────────────────────────────────
map("n", "<leader>-", "<C-w>s", { desc = "Split window below" })
map("n", "<leader>|", "<C-w>v", { desc = "Split window right" })
map("n", "<leader>wd", "<C-w>c", { desc = "Delete window" })

-- ───────────────────── toggles ───────────────────────────────────────────
map("n", "<leader>uw", function()
  vim.wo.wrap = not vim.wo.wrap
end, { desc = "Toggle wrap" })

map("n", "<leader>ud", function()
  vim.diagnostic.enable(not vim.diagnostic.is_enabled())
end, { desc = "Toggle diagnostics" })

map("n", "<leader>ul", function()
  local on = vim.wo.number or vim.wo.relativenumber
  vim.wo.number = not on
  vim.wo.relativenumber = not on
end, { desc = "Toggle line numbers" })

map("n", "<leader>uL", function()
  vim.wo.relativenumber = not vim.wo.relativenumber
end, { desc = "Toggle relative number" })

map("n", "<leader>uf", function()
  vim.g.autoformat = not vim.g.autoformat
  vim.notify("Autoformat (global) " .. (vim.g.autoformat and "enabled" or "disabled"))
end, { desc = "Toggle auto format (global)" })

map("n", "<leader>uF", function()
  vim.b.autoformat = vim.b.autoformat == false
  vim.notify("Autoformat (buffer) " .. (vim.b.autoformat and "enabled" or "disabled"))
end, { desc = "Toggle auto format (buffer)" })

-- ───────────────────── terminal ──────────────────────────────────────────
-- <C-/> sends <C-_> in most terminals; map both. Bottom split like LazyVim,
-- shares the <A-h> toggle (<A-i> floating term remains for the float style).
for _, key in ipairs { "<C-/>", "<C-_>" } do
  map({ "n", "t" }, key, function()
    require("nvchad.term").toggle { pos = "sp", id = "htoggleTerm" }
  end, { desc = "Terminal toggle" })
end

-- ───────────────────── git ───────────────────────────────────────────────
map("n", "<leader>gg", function()
  require("nvchad.term").toggle {
    pos = "float",
    id = "lazygit",
    cmd = "lazygit",
    float_opts = { width = 0.9, height = 0.9 },
  }
end, { desc = "Lazygit" })

-- ───────────────────── harpoon ───────────────────────────────────────────
map("n", "<leader>H", function()
  require("harpoon"):list():add()
end, { desc = "Harpoon file" })

map("n", "<leader>h", function()
  local harpoon = require "harpoon"
  harpoon.ui:toggle_quick_menu(harpoon:list())
end, { desc = "Harpoon quick menu" })

for i = 1, 5 do
  map("n", "<leader>" .. i, function()
    require("harpoon"):list():select(i)
  end, { desc = "Harpoon to file " .. i })
end

-- ───────────────────── dap ───────────────────────────────────────────────
map("n", "<leader>db", function()
  require("dap").toggle_breakpoint()
end, { desc = "Toggle breakpoint" })

map("n", "<leader>dB", function()
  require("dap").set_breakpoint(vim.fn.input "Breakpoint condition: ")
end, { desc = "Breakpoint condition" })

map("n", "<leader>dc", function()
  require("dap").continue()
end, { desc = "Run/continue" })

map("n", "<leader>da", function()
  require("dap").continue {
    before = function(config)
      config = vim.deepcopy(config)
      config.args = vim.split(vim.fn.input "Args: ", " +", { trimempty = true })
      return config
    end,
  }
end, { desc = "Run with args" })

map("n", "<leader>dC", function()
  require("dap").run_to_cursor()
end, { desc = "Run to cursor" })

map("n", "<leader>dg", function()
  require("dap").goto_()
end, { desc = "Go to line (no execute)" })

map("n", "<leader>di", function()
  require("dap").step_into()
end, { desc = "Step into" })

map("n", "<leader>dj", function()
  require("dap").down()
end, { desc = "Down" })

map("n", "<leader>dk", function()
  require("dap").up()
end, { desc = "Up" })

map("n", "<leader>dl", function()
  require("dap").run_last()
end, { desc = "Run last" })

map("n", "<leader>do", function()
  require("dap").step_out()
end, { desc = "Step out" })

map("n", "<leader>dO", function()
  require("dap").step_over()
end, { desc = "Step over" })

map("n", "<leader>dP", function()
  require("dap").pause()
end, { desc = "Pause" })

map("n", "<leader>dr", function()
  require("dap").repl.toggle()
end, { desc = "Toggle REPL" })

map("n", "<leader>ds", function()
  require("dap").session()
end, { desc = "Session" })

map("n", "<leader>dt", function()
  require("dap").terminate()
end, { desc = "Terminate" })

map("n", "<leader>dw", function()
  require("dap.ui.widgets").hover()
end, { desc = "Widgets" })

map("n", "<leader>du", function()
  require("dapui").toggle()
end, { desc = "Dap UI" })

map({ "n", "x" }, "<leader>de", function()
  require("dapui").eval()
end, { desc = "Eval" })

-- ───────────────────── database ──────────────────────────────────────────
-- NvChad's buffer-local LSP <leader>D (type definition) is removed in
-- configs/lspconfig.lua so it can't shadow this
map("n", "<leader>D", "<cmd>DBUIToggle<CR>", { desc = "Toggle DBUI" })
