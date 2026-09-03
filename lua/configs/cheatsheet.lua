-- Fixes NvChad's :NvCheatsheet for a LazyVim-style desc convention.
--
-- NvChad's own organize_mappings scrapes every keymap `desc` and then:
--
--   1. drops any mapping whose desc is a single word, so `desc = "Flash"`,
--      `desc = "Grep"` and `desc = "Todo"` never appear at all;
--   2. derives the section heading from the FIRST WORD of the desc and strips
--      that word from what it renders. `desc = "Next hunk"` therefore files
--      itself under a section literally named "Next" and displays as "Hunk".
--
-- Against this config that produced 69 sections named Next / Prev / Toggle /
-- Restore / Step / Don't, with a third of the keymaps missing. Rewriting ~150
-- descs into NvChad's "Group action" shape would fix the cheatsheet and wreck
-- which-key, which renders the desc verbatim.
--
-- So: keep the descs, replace the grouping. Sections come from the LHS prefix,
-- which is what which-key already groups on, and M.wk_spec() feeds this same
-- table into which-key so the two views cannot drift apart.
--
-- Section ordering in the "grid" theme comes from pairs() over the section
-- table, so it is arbitrary but stable: LuaJIT does not randomize string
-- hashes, so the layout stays put across opens as long as the section set is
-- unchanged. The "simple" theme sorts alphabetically if that matters more.

local M = {}

-- Sections, in three passes: an exact-LHS override, then the longest matching
-- LHS prefix, then a desc pattern. `wk` additionally registers the prefix as a
-- which-key group under the short name given.
--
-- Section names are the cheatsheet's, which-key's are the short ones: the
-- popup is read mid-keystroke and wants one word, the cheatsheet is read cold
-- and wants to say what the section is for.
M.groups = {
  { "<leader>a", "Claude Code", wk = "claude" },
  { "<leader>b", "Files & Buffers", wk = "buffer" },
  { "<leader>c", "LSP & Code", wk = "code" },
  { "<leader>d", "Debug (DAP)", wk = "debug" },
  { "<leader>f", "Search & Recon", wk = "find" },
  { "<leader>gh", "Git Hunks", wk = "hunks" },
  { "<leader>g", "Git & Review", wk = "git" },
  { "<leader>q", "Sessions", wk = "session" },
  { "<leader>R", "HTTP & DB", wk = "rest" },
  { "<leader>s", "Search & Recon", wk = "search" },
  { "<leader>t", "Tests", wk = "test" },
  { "<leader>u", "Toggles", wk = "toggles" },
  { "<leader>w", "Windows & Terminal", wk = "windows" },
  { "<leader>x", "Diagnostics", wk = "diagnostics" },
  { "gs", "Editing", wk = "surround" },

  -- harpoon owns a scattered set of leader keys rather than one prefix
  { "<leader>h", "Marks (Harpoon)" },
  { "<leader>H", "Marks (Harpoon)" },
  { "<leader>1", "Marks (Harpoon)" },
  { "<leader>2", "Marks (Harpoon)" },
  { "<leader>3", "Marks (Harpoon)" },
  { "<leader>4", "Marks (Harpoon)" },
  { "<leader>5", "Marks (Harpoon)" },

  -- cheatsheet-only buckets: real sections, but not prefixes worth
  -- advertising in which-key's popup. gr*/gO are Neovim's builtin LSP maps
  -- and gc* is commenting, so both outrank the bare `g` goto bucket.
  { "gr", "LSP & Code" },
  { "gO", "LSP & Code" },
  { "gc", "Editing" },
  { "g", "Jump & Goto" },
  { "]", "Jump & Goto" },
  { "[", "Jump & Goto" },

  { "<leader>", "Leader (misc)", fallback = true },
}

-- Exact-LHS assignments, checked first. These are the keys whose section is
-- not the one their prefix implies: reversing tooling is spread across the
-- toggle and code prefixes, and the fallback would file H/L/n/N under whatever
-- verb their desc happens to start with.
M.overrides = {
  ["H"] = "Files & Buffers",
  ["L"] = "Files & Buffers",
  ["<C-N>"] = "Files & Buffers",
  ["<leader>e"] = "Files & Buffers",
  ["<leader>,"] = "Files & Buffers",

  ["n"] = "Search & Recon",
  ["N"] = "Search & Recon",
  ["<leader>/"] = "Search & Recon",
  ["<leader>:"] = "Search & Recon",
  ["<leader><Space>"] = "Search & Recon",

  ["<leader>-"] = "Windows & Terminal",
  ["<leader>|"] = "Windows & Terminal",
  ["<leader>pt"] = "Windows & Terminal",

  ["<leader>D"] = "HTTP & DB",
  ["<leader>cm"] = "Git & Review",
  ["<leader>fm"] = "LSP & Code", -- NvChad files its format map under find
  ["<leader>th"] = "Toggles", -- NvChad's theme picker, inside the test prefix
  ["R"] = "Jump & Goto", -- flash treesitter_search; desc is "Treesitter search"

  -- hex.nvim and compiler-explorer are the RE/low-level pair; they sit on
  -- unrelated prefixes because the toggle and code groups own those letters
  ["<leader>uh"] = "Binary & Asm",
  ["<leader>cc"] = "Binary & Asm",
  ["<leader>cC"] = "Binary & Asm",
}

-- Checked after the prefixes but before the <leader> catch-all, for mappings
-- that belong together while sharing neither a prefix nor a first word.
-- Matched against a lowercased desc, because NvChad writes its own descs in
-- lowercase ("buffer goto next") and this config writes them in sentence case.
-- Order matters: the first pattern to match wins.
M.desc_rules = {
  -- flash owns s/S/r/R plus <C-s> in the cmdline: five different first words
  { "flash", "Jump & Goto" },
  { "terminal", "Windows & Terminal" },
  { "^switch window", "Windows & Terminal" },
  { "^show diagnostics", "Diagnostics" },
  { "^buffer", "Files & Buffers" },
  { "telescope", "Search & Recon" },
  { "^toggle", "Toggles" },
  { "^general", "Editing" },
  { "^move", "Editing" },
  { "^select", "Editing" },
  -- Neovim's own defaults describe themselves with the call they wrap
  -- ("vim.lsp.buf.signature_help()"), which the fallback would turn into a
  -- section per function
  { "^vim%.", "Neovim Builtins" },
}

-- Subcategories, per section, in the order they should render. Each rule is
-- { label, pattern-or-list }; the first rule whose pattern matches wins.
-- Patterns run against "<key>\t<lowercased desc>", so "^<leader>d" anchors on
-- the key while a bare word like "flash" matches either. Lua patterns have no
-- alternation, hence the lists. A section with no rules renders flat, exactly
-- as before.
M.subgroups = {
  ["Debug (DAP)"] = {
    { "breakpoints", "^<leader>d[bB]" },
    { "stepping", "^<leader>d[cCagiOoltP]" },
    { "lua (osv)", "^<leader>d[LN]" },
    { "inspect", "." },
  },
  ["Editing"] = {
    { "surround", "^gs" },
    { "comments", "^gc" },
    { "lines & selection", "." },
  },
  ["Jump & Goto"] = {
    { "flash", "flash" },
    { "diagnostics", { "diagnostic", "error", "warning" } },
    { "todo & context", { "todo", "context" } },
    { "treesitter nodes", "node" },
    { "goto", "." },
  },
  ["Search & Recon"] = {
    { "files", { "find files", "all files", "oldfiles", "buffers" } },
    { "grep", { "grep", "search and replace", "^n\t", "^N\t" } },
    { "pickers", "." },
  },
  ["Windows & Terminal"] = {
    { "terminal", "terminal" },
    { "windows", "." },
  },
  ["Tests"] = {
    { "run", "run " },
    { "inspect", "." },
  },
  ["LSP & Code"] = {
    { "neovim lsp defaults", { "^gr", "^gO" } },
    { "actions", "." },
  },
}

-- Ex commands worth knowing for the plugins added on top of NvChad, rendered
-- as a "commands" block at the foot of their section. Three of those plugins
-- ship no command at all (neotest, nvim-lint, osv), so their Lua entry points
-- are listed instead -- that is what `:lua ...` is doing here.
--
-- Keep the right-hand column under ~40 columns: both cheatsheet themes size
-- every column off the widest desc+key pair in the whole sheet, so one long
-- entry here drops the grid from three columns to two.
M.commands = {
  ["Binary & Asm"] = {
    { "hex view on/off", ":HexToggle" },
    { "buffer to hexdump", ":HexDump" },
    { "hexdump back to binary", ":HexAssemble" },
    { "compile on godbolt", ":CECompile" },
    { "recompile as you type", ":CECompileLive" },
    { "format via godbolt", ":CEFormat" },
    { "add library to compile", ":CEAddLibrary" },
    { "load a godbolt example", ":CELoadExample" },
    { "open this compile in browser", ":CEOpenWebsite" },
    { "docs for asm under cursor", ":CEShowTooltip" },
    { "jump to asm label", ":CEGotoLabel" },
    { "clear godbolt cache", ":CEDeleteCache" },
  },
  ["Git & Review"] = {
    { "list pull requests", ":Octo pr list" },
    { "check out this PR", ":Octo pr checkout" },
    { "start a review", ":Octo review start" },
    { "submit the review", ":Octo review submit" },
    { "list issues", ":Octo issue list" },
    { "new issue", ":Octo issue create" },
    { "add a comment", ":Octo comment add" },
    { "resolve a thread", ":Octo thread resolve" },
  },
  ["Tests"] = {
    { "run nearest", ':lua require"neotest".run.run()' },
    { "summary", ':lua require"neotest".summary.toggle()' },
  },
  ["Claude Code"] = {
    { "toggle the terminal", ":ClaudeCode" },
    { "resume a session", ":ClaudeCode --resume" },
    { "start / stop the server", ":ClaudeCodeStart" },
    { "is the CLI connected?", ":ClaudeCodeStatus" },
    { "attach a file by path", ":ClaudeCodeAdd %" },
    { "attach the tree selection", ":ClaudeCodeTreeAdd" },
    { "accept the open diff", ":ClaudeCodeDiffAccept" },
    { "reject the open diff", ":ClaudeCodeDiffDeny" },
    { "drop every open diff", ":ClaudeCodeCloseAllDiffs" },
  },
  ["Toggles"] = {
    { "sticky context on/off", ":TSContextToggle" },
    { "markdown render", ":RenderMarkdown toggle" },
    { "colour swatches", ":ColorizerToggle" },
    { "reattach colorizer", ":ColorizerReloadAllBuffers" },
  },
  ["LSP & Code"] = {
    { "lua LSP libraries", ":LazyDev lsp" },
    { "lint buffer", ':lua require"lint".try_lint()' },
  },
  ["Debug (DAP)"] = {
    { "debug server", ':lua require"osv".launch{port=8086}' },
    { "debug this file", ':lua require"osv".run_this()' },
  },
}

-- Width of the "-- label ----" rules that separate subcategories. Kept at or
-- under the widest real row so adding them cannot widen a column.
M.divider_width = 44

-- Sections to keep out of the cheatsheet entirely.
M.excluded = { "Autopairs" }

-- Longest desc rendered. Both themes size every column off the widest
-- desc+key pair in the whole sheet, and then divide the window by that, so a
-- single long row costs a column everywhere. Measured: at 36 the widest row is
-- 48 columns, which fits three columns from roughly 190 columns of terminal
-- up; at 40 the widest was 55 and the same terminal only fitted two.
M.max_desc = 36

-- v/x/s are the same thing to a reader; collapse them so a `{"n","x"}` map
-- renders as "(nv)" rather than "(nvx)".
local MODE_LABEL = { n = "n", i = "i", v = "v", x = "v", s = "v", o = "o", t = "t", c = "c" }
local MODE_ORDER = { n = 1, i = 2, v = 3, o = 4, t = 5, c = 6 }
local MODES = { "n", "i", "v", "x", "s", "o", "t", "c" }

--- nvim_get_keymap already returns `lhs` in readable <> notation, so running
--- it through keytrans would re-escape the angle brackets and print <lt>C-U>.
--- Only the leader needs handling: it comes back as a literal space.
local function pretty_lhs(lhs)
  local key = lhs:gsub("^ ", "<leader>")
  return (key:gsub(" ", "<Space>"))
end

local function section_for(key, desc)
  local override = M.overrides[key]
  if override then
    return override
  end

  local best, best_len, catch_all = nil, -1, nil
  for _, rule in ipairs(M.groups) do
    local prefix = rule[1]
    if key:sub(1, #prefix) == prefix then
      if rule.fallback then
        -- the <leader> catch-all must not outrank a desc rule, or every
        -- leader key lands in Leader (misc) before the rules are consulted
        catch_all = rule[2]
      elseif #prefix > best_len then
        best, best_len = rule[2], #prefix
      end
    end
  end
  if best then
    return best
  end

  local lower = desc:lower()
  for _, rule in ipairs(M.desc_rules) do
    if lower:find(rule[1]) then
      return rule[2]
    end
  end

  if catch_all then
    return catch_all
  end

  -- no rule matched: fall back to NvChad's heuristic, the first word of the
  -- desc. Letters only, so "vim.lsp.buf.rename()" can't become its own
  -- section, and "Harpoon to file 1" still lands in Harpoon.
  local first = desc:match "^%a+"
  return first and (first:gsub("^%l", string.upper)) or "Misc"
end

--- Replacement for nvchad.cheatsheet.organize_mappings.
--- Returns { [section] = { { desc, key }, ... } }.
function M.organize_mappings()
  local sections, index = {}, {}

  local function collect(mode, keymaps)
    for _, v in ipairs(keymaps) do
      local desc = v.desc
      local key = pretty_lhs(v.lhs)

      -- Neovim's own default maps describe themselves with the ex command or
      -- help tag they stand for (":rewind", ":help Y-default"). They are noise
      -- in a keybind reference and there are ~60 of them.
      local builtin = desc and desc:sub(1, 1) == ":"

      if desc and desc ~= "" and not builtin and not desc:find "\n" and not key:find "<Plug>" then
        local id = key .. "\0" .. desc
        local entry = index[id]

        if entry then
          -- same binding seen in another mode (e.g. mapped for {"n","v"})
          entry.modes[MODE_LABEL[mode]] = true
        else
          local name = section_for(key, desc)
          if not vim.tbl_contains(M.excluded, name) then
            entry = { desc = desc, key = key, modes = { [MODE_LABEL[mode]] = true } }
            index[id] = entry
            sections[name] = sections[name] or {}
            table.insert(sections[name], entry)
          end
        end
      end
    end
  end

  for _, mode in ipairs(MODES) do
    collect(mode, vim.api.nvim_get_keymap(mode))
    -- buffer-local maps (LSP, gitsigns, ft-scoped lazy keys) for whichever
    -- buffer was current when the cheatsheet was opened
    collect(mode, vim.api.nvim_buf_get_keymap(0, mode))
  end

  -- Both themes render an entry as `desc <padding> key` and never inspect it
  -- further, so a subcategory rule is just a row whose desc is the rule and
  -- whose key is empty. Nothing in NvChad has to know about it.
  local function divider(label)
    local text = "── " .. label .. " "
    local pad = M.divider_width - vim.fn.strdisplaywidth(text)
    return text .. string.rep("─", math.max(pad, 2))
  end

  local function render(e)
    local modes = vim.tbl_keys(e.modes)
    table.sort(modes, function(a, b)
      return MODE_ORDER[a] < MODE_ORDER[b]
    end)

    local key = e.key
    if #modes > 1 or modes[1] ~= "n" then
      key = key .. " (" .. table.concat(modes) .. ")"
    end

    -- NvChad's own descs are lowercase ("telescope find files") where this
    -- config's are sentence case; normalise so one column doesn't look ragged
    local desc = (e.desc:gsub("^%l", string.upper))
    if vim.fn.strchars(desc) > M.max_desc then
      desc = vim.fn.strcharpart(desc, 0, M.max_desc - 1) .. "…"
    end

    return { desc, key }
  end

  --- Split a section's entries into its declared subcategories, keeping the
  --- declared order rather than whichever bucket filled up first.
  local function bucketize(name, entries)
    local rules = M.subgroups[name] or {}
    local buckets, order = { [""] = {} }, { "" }

    for _, rule in ipairs(rules) do
      if not buckets[rule[1]] then
        buckets[rule[1]] = {}
        table.insert(order, rule[1])
      end
    end

    for _, e in ipairs(entries) do
      local hay = e.key .. "\t" .. e.desc:lower()
      local label = ""

      for _, rule in ipairs(rules) do
        local pats = type(rule[2]) == "table" and rule[2] or { rule[2] }
        for _, pat in ipairs(pats) do
          if hay:find(pat) then
            label = rule[1]
            break
          end
        end
        if label ~= "" then
          break
        end
      end

      table.insert(buckets[label], e)
    end

    return buckets, order
  end

  local out = {}

  for name, entries in pairs(sections) do
    table.sort(entries, function(a, b)
      return a.key < b.key
    end)

    local buckets, order = bucketize(name, entries)
    local commands = M.commands[name]

    if commands then
      buckets.commands = commands
      table.insert(order, "commands")
    end

    -- count how many blocks actually have content: with only one, the labels
    -- would be pure decoration, so the section stays flat
    local filled = 0
    for _, label in ipairs(order) do
      if #buckets[label] > 0 then
        filled = filled + 1
      end
    end

    local rows = {}

    for _, label in ipairs(order) do
      local bucket = buckets[label]

      if #bucket > 0 then
        if filled > 1 then
          -- the unlabelled lead block is the plain keymaps; name it so it
          -- reads as a peer of "commands" rather than as a missing heading
          table.insert(rows, { divider(label == "" and "keys" or label), "" })
        end

        for _, e in ipairs(bucket) do
          -- command entries are already { desc, key } literals
          table.insert(rows, label == "commands" and e or render(e))
        end
      end
    end

    out[name] = rows
  end

  return out
end

--- which-key group spec, generated from the same table the cheatsheet sections
--- on. Consumed by the which-key override in lua/plugins/init.lua.
function M.wk_spec()
  local spec = {}
  for _, g in ipairs(M.groups) do
    if g.wk then
      table.insert(spec, { g[1], group = g.wk })
    end
  end
  return spec
end

--- Swap the implementation into nvchad.cheatsheet. Both themes call
--- `require("nvchad.cheatsheet").organize_mappings()` at open time rather than
--- capturing it up front, so replacing the field is enough.
function M.setup()
  local ok, ch = pcall(require, "nvchad.cheatsheet")
  if ok then
    ch.organize_mappings = M.organize_mappings
  end
  return ok
end

return M
