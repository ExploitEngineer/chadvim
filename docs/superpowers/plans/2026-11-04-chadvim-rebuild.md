# chadvim rebuild Implementation Plan

> **For agentic workers:** execute inline with superpowers:executing-plans (the owner's standing rule: no subagent-driven execution). Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn chadvim into a NvChad-based review station for agent-written code: theme bug fixed, duplicated tools replaced by devaslife's picks, his review tools added, Claude Code moved to a herdr pane, every other plugin kept and working.

**Architecture:** NvChad v2.5 on lazy.nvim stays the base and owns all UI.
Theme freshness moves into one module that decides at startup whether the base46 cache is stale and recompiles it, and a real `wallbash` base46 theme replaces the startup highlight override.
Plugin swaps are lazy.nvim specs plus `enabled = false` stubs for NvChad's bundled plugins; every key that pointed at a removed plugin keeps its letters and points at the replacement.

**Tech Stack:** Neovim 0.12.5, NvChad v2.5, lazy.nvim, base46, snacks.nvim, oil.nvim, blink.cmp v1, mini.pairs, mini.diff (craftzdog fork), codediff.nvim, nvim-highlight-colors, gitlinker.nvim, mason-tool-installer.nvim, herdr 0.7.5, GNU stow.

**Spec:** `docs/superpowers/specs/2026-11-04-chadvim-rebuild-design.md`

## Global Constraints

- Neovim v0.12.5, NvChad branch `v2.5`, lazy.nvim. No `vim.pack`, no ui2, no tiny-cmdline, no lualine, incline, solarized-osaka or mini.icons.
- NvChad UI untouched: base46 and `<leader>th`, statusline, tabufline, nvdash, which-key, indent-blankline, nvim-web-devicons.
- The owner's existing keymaps keep their letters. New keys must not collide with any existing map (NvChad's `<leader>n` is taken).
- `chadrc.lua` must never contain a theme name other than the active one, in code or comments: NvChad's picker rewrites the old name to the new one with a file-wide `gsub` (`ui/lua/nvchad/utils.lua:24-35`).
- No em dash character anywhere. Markdown: one sentence per physical line.
- Lua formatted with mason's stylua (`~/.local/share/nvim/mason/bin/stylua`) per `.stylua.toml` (2 spaces, width 120, `call_parentheses = "None"`).
- Conventional Commits, no agent attribution anywhere, commits stay local until the owner asks to push.
- `lazy-lock.json` is committed in the same commit as the plugin change that moved it.
- Every task ends green on `tests/run.sh` and on `nvim --headless +qa` printing nothing.
- Owner checkpoints: after Task 2, after Task 10, after Task 11. Stop and wait at each.

## Review Focus

1. Base46 cache goes stale while Neovim is closed (HyDE theme changed, `chadrc.lua` edited outside Neovim, `git switch`): the next start must show the theme `chadrc.lua` names, with the current palette. Pinned by `theme_test.lua` stale-stamp cases (Task 1).
2. HyDE replaces `wall.dcol` by rename, not in-place write, so a watcher on the file's inode dies after the first change: live follow must survive two consecutive renames. Pinned in Task 1 live-follow test.
3. A partial or malformed `wall.dcol` (read mid-write, missing keys, no `dcol_mode`) must give a usable theme, falling back per slot, never an error. Pinned by the truncated fixture in Task 1.
4. Native diff mode keeps its own `]c`/`[c`: in a `:diffthis` window the keys jump between diff changes, not mini.diff hunks. Pinned in Task 7.
5. A public user starts Neovim outside herdr: the Claude terminal keys work with the native terminal; inside herdr they are absent. Pinned in Task 11 with the env var set and unset.

---

### Task 0: Branch, test harness, baseline

**Files:**
- Modify: `init.lua:1`
- Create: `tests/helpers.lua`, `tests/run.sh`, `tests/keymaps_test.lua`, `tests/bench.sh`

**Interfaces:**
- Produces: `T.eq(actual, expected, msg)`, `T.ok(cond, msg)`, `T.settle()`, `T.done()` in `tests/helpers.lua`; env `CHADVIM_BASE46_CACHE` honored by `init.lua`; `tests/run.sh` exits non-zero on any failure.

- [ ] **Step 1: Branch and commit pending work**

```bash
git switch -c feat/rebuild
git add lazy-lock.json && git commit -m "chore(lazy): update plugin lockfile"
git add docs/superpowers && git commit -m "docs: add rebuild spec and plan"
```
Leave `init.lua`, `lua/chadrc.lua` and `lua/wallbash_theme.lua` uncommitted: Task 1 rewrites them.

- [ ] **Step 2: Isolate the base46 cache for tests**

`init.lua:1` becomes `vim.g.base46_cache = vim.env.CHADVIM_BASE46_CACHE or vim.fn.stdpath "data" .. "/base46/"`.
Tests must never compile into the owner's real cache: a stale real cache is exactly the bug class in Review Focus 1.

- [ ] **Step 3: Write `tests/helpers.lua`**

`T.settle()` must make a headless run behave like a UI run: set `vim.g.ui_entered = true` and fire `UIEnter` (NvChad's `User FilePost` and lazy's `VeryLazy` wait on it), then `vim.wait` until scheduled callbacks (`lua/mappings.lua` loads via `vim.schedule`) have run.
`T.done()` quits with `cquit 1` when any assertion failed, `qall!` otherwise, and prints one `FAIL: <msg>` line per failure.

- [ ] **Step 4: Write `tests/run.sh`**

Runs every `tests/*_test.lua` as `nvim --headless -c "luafile <file>"`, each under `timeout 120`, with two per-file temp dirs: `CHADVIM_BASE46_CACHE` (empty) and `HYDE_CACHE_HOME` (a fresh copy of `tests/fixtures/hyde`, so tests can rewrite `wall.dcol` freely).
Prints `PASS <file>` or `FAIL <file>` plus the failure lines, exits 1 if any failed.

- [ ] **Step 5: Write `tests/keymaps_test.lua` (the audit that guards every swap)**

After `T.settle()`, open a Lua file from the repo so buffer-local LSP and gitsigns maps exist, then for every global and buffer map in modes `n`, `v`, `x`, `i`, `t`:
- if `rhs` matches `<cmd>(%u%w*)`, assert `vim.fn.exists(":" .. name) == 2`;
- assert `rhs` does not match any of a `REMOVED` list, empty in this task and grown by Tasks 3-8 (`"Telescope"`, `"NvimTree"`, `"Diffview"`, `"Colorizer"`).

- [ ] **Step 6: Run the audit against today's config**

Run: `tests/run.sh`
Expected: `PASS tests/keymaps_test.lua`. If it fails, today's config already has a dead key: fix it in this task.

- [ ] **Step 7: Write `tests/bench.sh` and record the baseline**

Median of 5 `nvim --headless --startuptime <tmp> +qa` runs, printing the final total in ms.
Run it and keep the number for Task 12 (it goes into `docs/STATE.md` in Task 13).

- [ ] **Step 8: Commit**

```bash
git add init.lua tests && git commit -m "test: add headless test harness and keymap audit"
```
`init.lua` here carries only the Step 2 line; stage it with `git add -p` so the uncommitted wallbash line stays out.

---

### Task 1: Real `wallbash` theme and a cache that cannot go stale

**Files:**
- Create: `lua/wallbash/palette.lua`, `lua/themes/wallbash.lua`, `lua/theme_cache.lua`, `tests/theme_test.lua`, `tests/fixtures/hyde/wall.dcol`, `tests/fixtures/dcol/dark.dcol`, `tests/fixtures/dcol/light.dcol`, `tests/fixtures/dcol/truncated.dcol`
- Modify: `init.lua:28-31`, `lua/chadrc.lua:8`
- Delete: `lua/wallbash_theme.lua`

**Interfaces:**
- Produces:
  - `palette.path() -> string`: `$HYDE_CACHE_HOME/wall.dcol`, default `~/.cache/hyde/wall.dcol`.
  - `palette.read(path: string) -> table<string,string>|nil`: `dcol_*` keys to `#rrggbb` (the `_rgba` keys ignored), plus `mode = "dark"|"light"`; `nil` when the file is missing or has no `dcol_pry1`.
  - `palette.to_base46(dcol: table|nil) -> { base_30: table, base_16: table, type: "dark"|"light" }`.
  - `palette.contrast(fg: string, bg: string) -> number` (WCAG ratio).
  - `theme_cache.stamp(theme: string) -> string`: the theme name, plus `size:mtime` of `palette.path()` when the theme is `wallbash`.
  - `theme_cache.load()`: recompile when the stored stamp differs, then dofile `defaults` and `statusline` from the cache.
  - `theme_cache.watch()`: live follow, starts only when the active theme is `wallbash`.

- [ ] **Step 1: Fixtures**

`tests/fixtures/dcol/dark.dcol` is a copy of the current `~/.cache/hyde/wall.dcol`.
`light.dcol` is a copy of `~/.cache/hyde/dcols/00c5658b0beef7244b0c3cea2ae633016f43e099.dcol` (`dcol_mode="light"`).
`truncated.dcol` is the first 10 lines of `dark.dcol`.
`tests/fixtures/hyde/wall.dcol` is a copy of `dark.dcol`.

- [ ] **Step 2: Write the failing tests in `tests/theme_test.lua`**

```lua
-- palette
local P = require "wallbash.palette"
local dark = P.read "tests/fixtures/dcol/dark.dcol"
T.eq(dark.dcol_pry1, "#16292e", "reads pry1")
T.eq(dark.mode, "dark", "reads mode")
T.eq(P.read "tests/fixtures/dcol/missing.dcol", nil, "missing file is nil")

for _, name in ipairs { "dark", "light", "truncated" } do
  local t = P.to_base46(P.read("tests/fixtures/dcol/" .. name .. ".dcol"))
  T.ok(vim.tbl_count(t.base_30) >= 30, name .. ": full base_30")
  T.eq(vim.tbl_count(t.base_16), 16, name .. ": full base_16")
  for _, slot in ipairs { "base05", "base08", "base09", "base0A", "base0B", "base0C", "base0D", "base0E", "base0F" } do
    T.ok(P.contrast(t.base_16[slot], t.base_16.base00) >= 4.5, name .. ": " .. slot .. " readable")
  end
  -- base46 paints Comment and @comment with base_30.grey_fg (integrations/defaults.lua:15)
  T.ok(P.contrast(t.base_30.grey_fg, t.base_16.base00) >= 3.0, name .. ": comments readable")
end
T.eq(P.to_base46(P.read "tests/fixtures/dcol/light.dcol").type, "light", "light mode")
T.eq(P.to_base46(nil).base_30.black, "#0B0E14", "no HyDE: ayu_dark fallback")

-- the reported bug: a non-wallbash theme is never overridden
require("nvconfig").base46.theme = "ayu_dark"
require("theme_cache").load()
T.eq(hl_bg "Normal", "#0b0e14", "ayu_dark Normal survives wall.dcol being present")

-- stale cache: stamp mismatch recompiles
require("nvconfig").base46.theme = "wallbash"
require("theme_cache").load()
local before = hl_bg "Normal"
copy("tests/fixtures/dcol/light.dcol", vim.env.HYDE_CACHE_HOME .. "/wall.dcol") -- new size and mtime
require("theme_cache").load()
T.ok(hl_bg "Normal" ~= before, "palette change while closed is picked up at load")
```
`hl_bg(name)` and `copy(src, dst)` are local helpers in the test file.
`HYDE_CACHE_HOME` is the per-file temp copy `run.sh` makes, so the copy never edits the fixture.

- [ ] **Step 3: Run to verify it fails**

Run: `tests/run.sh`
Expected: FAIL in `theme_test.lua` with `module 'wallbash.palette' not found`.

- [ ] **Step 4: Implement `lua/wallbash/palette.lua`**

Mapping rules (owner-approved direction, exact slots are a builder call):
- `black` is `dcol_pry1`, `white` is `dcol_txt1`; the greys (`darker_black`, `black2`, `one_bg`, `one_bg2`, `one_bg3`, `grey`, `grey_fg`, `grey_fg2`, `light_grey`, `line`, `statusline_bg`, `lightbg`) are a lightness ramp off `black` with base46's `base46.colors.change_hex_lightness`, lighter for dark mode and darker for light mode.
- Semantic slots stay semantic so errors stay red and additions green: `red`, `baby_pink`, `pink`, `green`, `vibrant_green`, `yellow`, `sun`, `orange` come from the fallback theme.
- Accent slots (`blue`, `nord_blue`, `purple`, `dark_purple`, `teal`, `cyan`, `pmenu_bg`, `folder_bg`) and syntax slots `base08`-`base0F` come from the four `dcol_Nxa7`/`dcol_Nxa8` accents.
- Any fg slot below the contrast floor against `base00` (4.5 for `base05` and `base08`-`base0F`, 3.0 for `grey_fg`, which base46 uses for comments) is stepped in lightness away from `base00` until it passes.
- Any missing key falls back to the same slot of the fallback theme.
- The fallback is `require("base46.themes.ayu_dark")`, deep-copied. Its name appears only in this file, never in `chadrc.lua`.

- [ ] **Step 5: Implement `lua/themes/wallbash.lua`**

Returns `palette.to_base46(palette.read(palette.path()))` with `polish_hl = {}`, then `require("base46").override_theme(M, "wallbash")` like every base46 theme.

- [ ] **Step 6: Implement `lua/theme_cache.lua` and wire it in**

`load()` writes the stamp to `vim.g.base46_cache .. "chadvim_stamp"` after compiling.
Before every theme compile it clears `package.loaded["themes.wallbash"]` so the palette is re-read.
`init.lua:28-31` (the two `dofile` lines and the wallbash line) becomes `require("theme_cache").load()`.
Delete `lua/wallbash_theme.lua`. Set `theme = "wallbash"` in `lua/chadrc.lua`.
Add `theme_cache.watch()` to `lua/autocmds.lua`.

- [ ] **Step 7: Run to verify it passes**

Run: `tests/run.sh`
Expected: all PASS.

- [ ] **Step 8: Live follow test, then implementation**

Add to `theme_test.lua`: with theme `wallbash`, call `watch()`, then twice replace `wall.dcol` by writing a temp file in the same dir and `os.rename` over it (dark, then light, then dark).
After each, `vim.wait(3000, ...)` until `Normal` bg changes, and assert it did.
Implement `watch()` with `vim.uv.new_fs_event` on the directory of `palette.path()` (not the file), filtered to the `wall.dcol` filename, debounced 200 ms, calling the same reload NvChad's picker uses (`nvchad.themes.utils.reload_theme("wallbash")`) only while `require("nvconfig").base46.theme == "wallbash"`.
Run: `tests/run.sh`. Expected: all PASS.

- [ ] **Step 9: E2E check in the real UI**

In a kitty window: `nvim lua/chadrc.lua`, `<leader>th`, confirm `wallbash` is listed, pick `ayu_dark`, `ZR`, confirm colors are ayu everywhere (buffer, statusline, tabufline, which-key).
Pick `wallbash`, switch the HyDE theme from the desktop, confirm the open Neovim repaints.
Switch HyDE to a light theme and confirm the Lazy button row (`:Lazy`) is readable.
Screenshot each state with `grim` and the window geometry from `hyprctl clients -j`.

- [ ] **Step 10: Commit**

```bash
git add init.lua lua/chadrc.lua lua/autocmds.lua lua/wallbash lua/themes lua/theme_cache.lua tests
git rm --cached lua/wallbash_theme.lua 2>/dev/null; rm -f lua/wallbash_theme.lua
git commit -m "fix(theme): make wallbash a real base46 theme and keep the cache fresh"
```

---

### Task 2: Take Neovim out of the dotfiles repo

**Files (in `~/dotfiles`):**
- Delete: `cli/.config/nvim/init.lua`, `cli/.config/nvim/lua/wallbash_theme.lua`
- Modify: `README.md:34`, `README.md:48`

- [ ] **Step 1: Branch and remove**

```bash
git -C ~/dotfiles switch -c chore/nvim-lives-in-chadvim
git -C ~/dotfiles rm -r cli/.config/nvim
```

- [ ] **Step 2: README**

Line 34 drops "nvim's wallbash hook" from the `cli/` row.
Line 48 says Neovim follows wallbash through chadvim's `wallbash` base46 theme, linking `https://github.com/ExploitEngineer/chadvim`.

- [ ] **Step 3: Verify stow is clean**

Run: `stow --no --verbose --restow --target "$HOME" --dir ~/dotfiles cli`
Expected: no line mentions `.config/nvim`, no conflicts.

- [ ] **Step 4: Commit**

```bash
git -C ~/dotfiles commit -am "chore(cli): drop nvim files, chadvim owns ~/.config/nvim"
```

- [ ] **Step 5: Owner checkpoint 1.** Stop. The owner tries the picker, `ZR`, and a HyDE theme switch.

---

### Task 3: Picker: telescope to snacks

**Files:**
- Create: `lua/plugins/snacks.lua`
- Modify: `lua/plugins/init.lua:50-94` (telescope spec), `lua/mappings.lua:26-27,52-61`, `lua/configs/lspconfig.lua:16-19,27-28`, `lua/plugins/editor.lua:83-84`, `lua/plugins/git.lua:52-61`, `lua/configs/cheatsheet.lua:119`, `lua/plugins/claude.lua:11-15,32-35` (comments that say snacks is avoided), `tests/keymaps_test.lua`

**Interfaces:**
- Produces: `Snacks` global available from startup (`lazy = false`, `priority = 1000`), with `picker` and `picker.ui_select = true`. Tasks 10 adds modules to this same spec.

- [ ] **Step 1: Extend the audit**

Add `"Telescope"` to `REMOVED` and assert `require("lazy.core.config").plugins["telescope.nvim"] == nil`.
Also assert `debug.getinfo(vim.ui.select, "S").source:find("snacks", 1, true)`.

- [ ] **Step 2: Run to verify it fails**

Run: `tests/run.sh`. Expected: FAIL naming the first Telescope key.

- [ ] **Step 3: Implement**

`{ "nvim-telescope/telescope.nvim", enabled = false }` replaces the whole telescope spec (the ui-select shim goes with it).
Same letters, snacks pickers:

| Key | snacks |
|---|---|
| `<leader><space>`, `<leader>ff` | `files` |
| `<leader>fa` | `files { hidden = true, ignored = true, follow = true }` |
| `<leader>/`, `<leader>sg`, `<leader>fw` | `grep` |
| `<leader>sw` | `grep_word` |
| `<leader>,`, `<leader>fb` | `buffers` |
| `<leader>:` | `command_history` |
| `<leader>sb`, `<leader>fz` | `lines` |
| `<leader>sk` | `keymaps` |
| `<leader>sh`, `<leader>fh` | `help` |
| `<leader>sR` | `resume` |
| `<leader>ma` | `marks` |
| `<leader>fo` | `recent` |
| `<leader>cm` | `git_log` |
| `<leader>gt` | `git_status` |
| `gd`, `gr`, `gI`, `gy` | `lsp_definitions`, `lsp_references`, `lsp_implementations`, `lsp_type_definitions` |
| `<leader>ss`, `<leader>sS` | `lsp_symbols`, `lsp_workspace_symbols` |
| `<leader>st`, `<leader>sT` | `todo_comments`, `todo_comments { keywords = { "TODO", "FIX", "FIXME" } }` |

NvChad's `<leader>pt` (pick hidden NvChad term) has no snacks equivalent: delete it.
Octo: `picker = "snacks"`, dependency swapped to `folke/snacks.nvim`.
Cheatsheet: the `telescope` desc rule becomes a `picker` rule in the same section.

- [ ] **Step 4: Run to verify it passes**

Run: `tests/run.sh`. Expected: all PASS.

- [ ] **Step 5: E2E**

Screenshots of `<leader><space>`, `<leader>/`, `gr` in a real project, and `:CECompile` in a C file (its ~900-entry `vim.ui.select` list must open in the snacks picker, not the `-- More --` prompt).

- [ ] **Step 6: Commit**

`feat(picker): replace telescope with snacks picker`, including `lazy-lock.json`.

---

### Task 4: Explorer: nvim-tree to oil

**Files:**
- Modify: `lua/plugins/editor.lua` (add oil), `lua/plugins/init.lua` (disable nvim-tree), `lua/mappings.lua:26`, `lua/plugins/claude.lua:62`, `lua/plugins/ui.lua:13`, `tests/keymaps_test.lua`
- Create: `tests/explorer_test.lua`

- [ ] **Step 1: Failing tests**

Audit: add `"NvimTree"` to `REMOVED`, assert `plugins["nvim-tree.lua"] == nil`.
`explorer_test.lua`: `vim.cmd.edit(vim.fn.getcwd())` then `T.eq(vim.bo.filetype, "oil", "a directory opens in oil")`.

- [ ] **Step 2: Run to verify it fails.** Expected: FAIL on the NvimTree key.

- [ ] **Step 3: Implement**

oil with `default_file_explorer = true` and loaded early enough that `nvim .` lands in oil (netrw is already disabled in `lua/configs/lazy.lua`).
`<leader>e` and NvChad's `<C-n>` open oil as a float on the current file's directory, with preview.
claudecode's `<leader>at` uses `ft = "oil"`.

- [ ] **Step 4: Run to verify it passes.** Expected: all PASS.

- [ ] **Step 5: E2E.** `nvim .` lands in oil, not nvdash. `<leader>e` float screenshot. Rename a file in oil and save, confirm on disk.

- [ ] **Step 6: Commit** `feat(explorer): replace nvim-tree with oil`, with `lazy-lock.json`.

---

### Task 5: Completion: nvim-cmp to blink.cmp

**Files:**
- Create: `lua/plugins/completion.lua`, `tests/completion_test.lua`
- Modify: `lua/plugins/init.lua:30-46` (the nvim-cmp lazydev block goes), `lua/plugins/lang.lua:11-17` (crates), `lua/chadrc.lua:11` (integrations)

- [ ] **Step 1: Failing test**

```lua
for _, p in ipairs { "nvim-cmp", "LuaSnip", "cmp_luasnip", "cmp-nvim-lsp", "cmp-nvim-lua", "cmp-buffer", "cmp-async-path" } do
  T.eq(require("lazy.core.config").plugins[p], nil, p .. " removed")
end
local cfg = require("blink.cmp.config")
T.ok(vim.tbl_contains(cfg.sources.default, "lsp") and vim.tbl_contains(cfg.sources.default, "snippets"), "default sources")
T.ok(cfg.sources.per_filetype.lua and vim.tbl_contains(cfg.sources.per_filetype.lua, "lazydev"), "lazydev on lua")
T.ok(cfg.sources.per_filetype.sql and vim.tbl_contains(cfg.sources.per_filetype.sql, "dadbod"), "dadbod on sql")
T.eq(cfg.completion.list.selection.preselect, false, "nothing preselected")
```

- [ ] **Step 2: Run to verify it fails.** Expected: FAIL `nvim-cmp removed`.

- [ ] **Step 3: Implement**

blink.cmp `version = "1.*"` (prebuilt fuzzy binary; first install downloads it), `event = "InsertEnter"`, keymap preset `enter` plus `<Tab>`/`<S-Tab>` select next/prev, `completion.list.selection = { preselect = false, auto_insert = true }`, docs auto-show.
Sources: `lsp`, `path`, `snippets` (friendly-snippets stays as a blink dependency), `buffer`; `lazydev` via `lazydev.integrations.blink` on `lua`; `dadbod` via `vim_dadbod_completion.blink` on `sql`, `mysql`, `plsql`.
crates.nvim: drop `completion.cmp`, enable its in-process LSP with `completion = true`.
Disable nvim-cmp and LuaSnip with `enabled = false` stubs.
Add `"blink"` to `M.base46.integrations`.

- [ ] **Step 4: Run to verify it passes.** Expected: all PASS.

- [ ] **Step 5: E2E.** Menu screenshot in a TS file, Lua file (lazydev items), `Cargo.toml` (crates versions), a `.sql` buffer with a DBUI connection.

- [ ] **Step 6: Commit** `feat(completion): replace nvim-cmp with blink.cmp`, with `lazy-lock.json`.

---

### Task 6: Pairs: nvim-autopairs to mini.pairs

**Files:**
- Modify: `lua/plugins/completion.lua`, `lua/configs/cheatsheet.lua:243`, `tests/completion_test.lua`

- [ ] **Step 1: Failing test**

```lua
T.eq(require("lazy.core.config").plugins["nvim-autopairs"], nil, "autopairs removed")
vim.cmd.enew()
vim.api.nvim_feedkeys(vim.keycode "i(<Esc>", "xt", false)
T.eq(vim.api.nvim_get_current_line(), "()", "mini.pairs closes (")
```

- [ ] **Step 2: Run to verify it fails.**
- [ ] **Step 3: Implement** mini.pairs on `InsertEnter`, `enabled = false` stub for nvim-autopairs, cheatsheet exclude updated to mini.pairs' desc.
- [ ] **Step 4: Run to verify it passes.**
- [ ] **Step 5: Commit** `feat(editor): replace nvim-autopairs with mini.pairs`, with `lazy-lock.json`.

---

### Task 7: Diff review: diffview to codediff and mini.diff

**Files:**
- Modify: `lua/plugins/git.lua:36-43`, `lua/chadrc.lua:11` (drop `diffview`), `tests/keymaps_test.lua`
- Create: `tests/diff_test.lua`

**Interfaces:**
- Produces: `<leader>gd` codediff explorer, `<leader>gf` codediff history of the current file, `<leader>gF` codediff history of the repo, `<leader>ug` toggle mini.diff overlay, `]c`/`[c` mini.diff hunk jumps outside diff mode.

- [ ] **Step 1: Failing tests**

Audit: add `"Diffview"` to `REMOVED`; assert `plugins["diffview.nvim"] == nil` and `vim.fn.exists(":CodeDiff") == 2`.
`diff_test.lua`, in a temp git repo with one committed file of 20 lines:
- change line 15, `:edit`, `T.settle()`, then `]c` from line 1 lands on line 15 (mini.diff);
- `:vsplit | diffthis` against an altered copy, `]c` lands on the native diff change, not the mini.diff hunk (Review Focus 4);
- the sign column holds gitsigns signs only: `vim.fn.sign_getplaced` and extmarks in mini.diff's namespace carry no sign text.

- [ ] **Step 2: Run to verify it fails.**

- [ ] **Step 3: Implement**

mini.diff from `craftzdog/mini.diff`, `branch = "feat/grouping"`, on `User FilePost`, `view.overlay_style = "hunk"`, `mappings.goto_next = "]c"`, `goto_prev = "[c"`, signs hidden without reserving sign-column width.
Read his block in `dot_config/nvim/lua/craftzdog/plugins/editor.lua:70-84` of `github.com/craftzdog/dotfiles` for the exact option shape.
`]c`/`[c` defer to native behavior when `vim.wo.diff` is set.
codediff.nvim on `cmd = "CodeDiff"` with the three keys above. Its first run may download a prebuilt diff library.

- [ ] **Step 4: Run to verify it passes.**
- [ ] **Step 5: E2E.** Screenshots: `<leader>gd` explorer on a dirty repo, `<leader>ug` overlay on and off, `<leader>gf` history.
- [ ] **Step 6: Commit** `feat(git): replace diffview with codediff and mini.diff overlay`, with `lazy-lock.json`.

---

### Task 8: Color codes: nvim-colorizer to nvim-highlight-colors

**Files:**
- Modify: `lua/plugins/ui.lua:2-29`, `lua/configs/cheatsheet.lua:225-226`, `tests/keymaps_test.lua`
- Create: `tests/colors_test.lua`

- [ ] **Step 1: Failing test.** Audit: add `"Colorizer"` to `REMOVED`, assert `plugins["nvim-colorizer.lua"] == nil`. `colors_test.lua`: buffer with `color: #ff0000;` (ft `css`), `T.settle()`, assert at least one extmark in any namespace whose name contains `highlight`.
- [ ] **Step 2: Run to verify it fails.**
- [ ] **Step 3: Implement.** Keep today's look: inline virtual symbol `󱓻` before the code, tailwind on, named colors off, same excluded filetypes (minus `NvimTree` and `TelescopePrompt`, which no longer exist). Cheatsheet entries point at `:HighlightColors Toggle`.
- [ ] **Step 4: Run to verify it passes.**
- [ ] **Step 5: Commit** `feat(ui): replace nvim-colorizer with nvim-highlight-colors`, with `lazy-lock.json`.

---

### Task 9: Agent helpers and editor behaviors

**Files:**
- Create: `lua/utils/agent_paths.lua`, `tests/agent_paths_test.lua`
- Modify: `lua/mappings.lua`, `lua/options.lua`, `lua/autocmds.lua`, `lua/configs/cheatsheet.lua` (new `<leader>y` group)

**Interfaces:**
- Produces:
  - `agent_paths.relative_ref(bufnr: integer, l1: integer, l2?: integer) -> string`: `lua/x.lua#L12` or `lua/x.lua#L12-L20`, relative to cwd.
  - `agent_paths.absolute_ref(bufnr, l1, l2?) -> string`: same with the absolute path.
  - `agent_paths.code_block(bufnr, l1, l2) -> string`: a fenced block whose info string is `<filetype> <relative_ref>`, then the lines verbatim.
  - Keys: `<leader>yf` relative ref of the cursor line (visual: of the selection), `<leader>yp` absolute ref, visual `<leader>yc` code block. All copy to `+`.

- [ ] **Step 1: Failing tests**

```lua
local A = require "utils.agent_paths"
vim.cmd.edit "lua/options.lua"
T.eq(A.relative_ref(0, 12), "lua/options.lua#L12", "relative single")
T.eq(A.relative_ref(0, 12, 20), "lua/options.lua#L12-L20", "relative range")
T.eq(A.absolute_ref(0, 3), vim.fn.getcwd() .. "/lua/options.lua#L3", "absolute")
T.eq(vim.split(A.code_block(0, 1, 1), "\n")[1], "```lua lua/options.lua#L1", "fence info")
T.ok(vim.o.winborder == "rounded", "rounded floats")
```
Plus: after `vim.cmd.split()` and `wincmd p`, the inactive window has `cursorline` off and the active one on.

- [ ] **Step 2: Run to verify it fails.**
- [ ] **Step 3: Implement** the module, the keys, `vim.o.winborder = "rounded"` in `lua/options.lua`, and a `WinEnter`/`WinLeave` cursorline autocmd. ignorecase, smartcase, undofile and yank highlight already exist (NvChad options and `lua/autocmds.lua:5`): leave them.
- [ ] **Step 4: Run to verify it passes.**
- [ ] **Step 5: Commit** `feat(agent): copy file refs and code blocks for agent prompts`.

---

### Task 10: snacks extras, gitlinker, mason-tool-installer, theme pass

**Files:**
- Modify: `lua/plugins/snacks.lua`, `lua/plugins/git.lua`, `lua/plugins/init.lua` (mason-tool-installer next to mason), `lua/mappings.lua:131-139` (`<leader>gg`), `lua/chadrc.lua` (`hl_add` patches)
- Create: `tests/contrast_test.lua`

- [ ] **Step 1: Failing tests**

`contrast_test.lua`: for themes `wallbash`, `ayu_dark` and `one_light`, load the theme into the isolated cache, open each float (snacks picker, snacks notifier history, oil float, blink menu with a forced `show()`), and for every highlight group in this list assert resolved fg against resolved bg (falling back to `NormalFloat`, then `Normal`) is at least 3.0: `SnacksPickerMatch`, `SnacksPickerDir`, `SnacksPickerFile`, `SnacksPickerPrompt`, `SnacksNotifierInfo`, `SnacksNotifierTitleInfo`, `OilDir`, `OilFile`, `BlinkCmpMenu`, `BlinkCmpLabelMatch`, `BlinkCmpMenuSelection`, `MiniDiffOverAdd`, `MiniDiffOverDelete`, `MiniDiffOverChange`.
Plus: `require("mason-tool-installer")` options `ensure_installed` equals `require("chadrc").mason.pkgs` and `auto_update == false`.

- [ ] **Step 2: Run to verify it fails.**

- [ ] **Step 3: Implement**

snacks: `notifier`, `lazygit`, `words` enabled; `indent`, `statuscolumn`, `dashboard`, `scroll` explicitly off.
`<leader>gg` becomes `Snacks.lazygit()` (it themes lazygit from the active colors and opens files back in this Neovim), with delta as lazygit's pager (Task 11 ships that lazygit config).
`<leader>sn` opens notification history.
gitlinker on `cmd = "GitLink"`, `<leader>gy` copies the permalink in `n` and `v`.
mason-tool-installer fed from `chadrc` `M.mason.pkgs`, `auto_update = false`.
Patch every group the contrast test flags with `hl_add`/`hl_override` in `chadrc.lua`, using base46 color names, never theme names.

- [ ] **Step 4: Run to verify it passes.**
- [ ] **Step 5: E2E.** Screenshot every float in all three themes. Fix anything that looks off even if the ratio passes.
- [ ] **Step 6: Commit** `feat: add snacks notifier and lazygit, gitlinker, mason-tool-installer`, with `lazy-lock.json`.
- [ ] **Step 7: Owner checkpoint 2.** Stop. The owner uses the picker, oil, completion, the diff tools and lazygit on a real project.

---

### Task 11: Agent workflow with herdr

**Files:**
- Create: `lua/utils/herdr.lua`, `tests/claude_test.lua`, `~/dotfiles/terminal/.config/herdr/config.toml`, `~/dotfiles/cli/.config/lazygit/config.yml`
- Modify: `lua/plugins/claude.lua`

**Interfaces:**
- Produces: `herdr.inside() -> boolean`, true when `vim.env.HERDR_PANE_ID` is set (the name comes from the herdr 0.7.5 binary; Step 1 confirms it in a live pane).

- [ ] **Step 1: Confirm the env var.** In a herdr pane: `env | grep '^HERDR_'`. Expected: `HERDR_PANE_ID` present. If not, use the variable that is, and fix the interface line above.

- [ ] **Step 2: Failing test**

`claude_test.lua` runs twice from `run.sh`, once with `HERDR_PANE_ID=test` and once without:
- inside: claudecode `terminal.provider == "none"`, and no map exists for `<leader>ac`, `<leader>af`, `<leader>ar`;
- outside: provider `"native"`, and all three exist;
- both: `<leader>as` (visual), `<leader>ab`, `<leader>aa`, `<leader>ad`, `<leader>aq`, `<leader>aS`, `<leader>am` exist.

- [ ] **Step 3: Run to verify it fails.**
- [ ] **Step 4: Implement** `lua/utils/herdr.lua` and the conditional provider and keys in `lua/plugins/claude.lua`.
- [ ] **Step 5: Run to verify it passes.**

- [ ] **Step 6: herdr and lazygit config in dotfiles**

Move `~/.config/herdr/config.toml` to `~/dotfiles/terminal/.config/herdr/config.toml`, then stow `terminal`.
Content: `onboarding = false`, `[ui] sidebar_start_collapsed = true`, `[ui.sidebar.agents.rows_by_agent] claude = [["state_icon", "workspace", "tab"], ["terminal_title_stripped"]]`, `[terminal] new_cwd = "follow"`, and one `[[keys.command]]` of `type = "pane"` running `cd "$HERDR_ACTIVE_PANE_CWD" && lazygit` on a key unbound in herdr's defaults.
Lazygit config: `git.paging.pager: delta --dark --paging=never` (light HyDE themes need `--light`; follow `dcol_mode` only if lazygit supports a per-run pager override, otherwise leave dark and note it).
Verify: `herdr config check` prints no errors (report any unknown key to the owner, do not drop it), `ls -la ~/.config/herdr/config.toml` is a symlink, `~/.config/herdr` is still a real directory, `git -C ~/dotfiles status` shows no socket, log or session file.
Commit in dotfiles: `feat(terminal): add herdr and lazygit configs`.

- [ ] **Step 7: E2E in herdr**

One workspace on a real project, Neovim left, `claude` right.
`/ide` lists this Neovim; a visual `<leader>as` reaches Claude; a Claude edit opens as a diff in Neovim; `<leader>aa` accepts.
Edit the open file from the Claude pane and switch focus: the buffer reloads. If it does not, herdr is not forwarding focus events: fix it (herdr setting, or a timer-driven `checktime` only while a herdr pane is unfocused).
`ZR`: Neovim returns with its windows and buffers, nvdash does not cover them, the Claude pane keeps running, and `/ide` reconnects (note in README if a manual `/ide` is needed).
Sessions: `:restart` and persistence.nvim do not double-restore.
Two workspaces, two Neovims: each Claude attaches to its own Neovim.

- [ ] **Step 8: Commit** `feat(claude): run Claude in herdr and bridge it with claudecode`.

- [ ] **Step 9: Owner checkpoint 3.** Stop. Also ask the owner whether to run `herdr integration install claude`: it writes a hook into `~/.claude/hooks` for exact agent-state detection, which is outside both repos.

---

### Task 12: Kept plugins and clean-up

**Files:**
- Create: `tests/plugins_test.lua`
- Modify: `lua/plugins/*.lua` (merge `typr.lua` and `wakatime.lua` into `tools.lua`), any file with stale comments about removed plugins

- [ ] **Step 1: Failing test**

`plugins_test.lua`: for each kept plugin (the spec's "Kept as is" list), `require("lazy").load { plugins = { name } }` adds no `ErrorMsg` to `:messages`.
After `T.settle()`, `require("lazy").stats().loaded` is at most the startup set recorded here: NvChad core, snacks, oil, rustaceanvim, vim-wakatime.

- [ ] **Step 2: Run, fix each failure, run again.** Expected: all PASS.

- [ ] **Step 3: Grep for leftovers.** `rg -n -i 'telescope|nvimtree|nvim-tree|diffview|colorizer|nvim-cmp|luasnip|autopairs' lua docs/CODE-TOUR.md docs/CONCEPTS.md` returns only intentional `enabled = false` stubs. Fix the rest.

- [ ] **Step 4: Bench.** `tests/bench.sh` is at or below the Task 0 baseline. If not, find the plugin with `--startuptime` and lazy-load it.

- [ ] **Step 5: Format and commit.** `stylua lua tests`, then `refactor: tidy plugin layout and lazy-loading`.

---

### Task 13: Docs for publishing

**Files:**
- Create: `AGENTS.md`, `CLAUDE.md` (symlink to `AGENTS.md`), `docs/STATE.md`, `docs/DECISIONS.md`
- Modify: `README.md`, `docs/CODE-TOUR.md`, `docs/CONCEPTS.md`

- [ ] **Step 1: `AGENTS.md`** (at most about 120 lines): commands (`tests/run.sh`, `tests/bench.sh`, stylua), architecture map, hard rules from Global Constraints (picker `gsub` hazard, isolated test cache, no theme names in `chadrc.lua`).
- [ ] **Step 2: `docs/DECISIONS.md`**: one numbered, dated, `Active` entry per spec decision (swaps, wallbash theme and stale-stamp cache, herdr outside Neovim, claudecode bridge, gitsigns versus mini.diff split, mini.diff fork with upstream fallback, herdr version 0.7.5).
- [ ] **Step 3: `docs/STATE.md`** (at most about 80 lines): shipped, known gaps from the E2E runs, baseline and final startup times, up to 3 ideas, ending `verified: <sha> 2026-11-04`.
- [ ] **Step 4: `README.md`** for public users: what it is, screenshots from the E2E runs, install, required tools (`fd`, `git-delta`, `lazygit`, `ripgrep`, `tree-sitter`, a Nerd Font), the herdr layout (with the tip: one git worktree and one herdr workspace per agent when several agents work on one repo), how the theme follows HyDE and falls back without it, credit to devaslife linking his dotfiles and video. No text copied from his config.
- [ ] **Step 5: Verify** no em dash: `rg -n '\x{2014}' AGENTS.md README.md docs` returns nothing.
- [ ] **Step 6: Commit** `docs: document the rebuilt config for publishing`.
