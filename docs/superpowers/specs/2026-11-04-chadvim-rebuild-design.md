# chadvim rebuild: agentic review setup on NvChad

Date: 2026-11-04
Status: draft, awaiting owner approval

## Why

The owner now writes almost no code by hand.
Claude Code writes it, and Neovim is used to review what the agent wrote, plus occasional hand-written practice.
The current config grew to 64 plugins and has overlapping tools, a broken theme override, and files owned by two repositories at once.

The direction comes from devaslife's video "Effective Neovim setup for agentic coding towards 2027" (2026-11-04) and his public dotfiles (github.com/craftzdog/dotfiles).
His setup treats Neovim as a review station next to an agent that runs outside the editor, in a herdr pane.
We take his tool choices and his workflow, but not his keybindings and not his UI.

The rebuilt config will be published (public repo `ExploitEngineer/chadvim`) and shown in an Instagram video later, so it must work for people who do not run HyDE.

## Goals

1. Fix the theme bug: picking a theme with the NvChad picker must stick across restarts, and a "follow HyDE" option must exist as a real theme.
2. Replace every tool that duplicates a job with the tool devaslife uses for that job (table below).
3. Add devaslife's review tools that have no equivalent today (table below).
4. Run Claude Code outside Neovim, in a herdr pane, following devaslife's layout, while keeping claudecode.nvim as a bridge.
5. Keep every other plugin the owner has today, working and properly lazy-loaded.
6. Leave the repo clean and documented enough to publish.

## Non-goals

- Changing the NvChad UI: base46 themes and the `<leader>th` picker, NvChad statusline, tabufline, nvdash, which-key, indent-blankline and nvim-web-devicons all stay.
- Adopting devaslife's keybindings. The owner's current LazyVim-style keymaps stay. Where a key pointed at a removed plugin, it keeps the same letters and points at the replacement.
- Moving off NvChad or lazy.nvim. No `vim.pack`, no ui2, no tiny-cmdline, no lualine, incline, solarized-osaka or mini.icons.
- Producing the Instagram video. That is a separate project after this one ships.

## Anti-goals (a technically working result that still fails)

- Any theme where some highlight groups come from one palette and others from another.
- Any key the owner presses that throws an error because its target plugin is gone.
- A slower startup than today's baseline.
- Plugins whose floats or pickers look visibly off-theme (unreadable text, wrong backgrounds) in the shipped themes.
- A config that errors on a machine without HyDE.

## Current state (verified 2026-11-04)

- Neovim v0.12.5, NvChad v2.5, lazy.nvim, 64 plugins in `lazy-lock.json`, about 2460 lines of Lua.
- Headless startup prints no messages.
- Theme bug, reproduced: `init.lua:31` calls `require("wallbash_theme").apply()` after base46 loads.
  It overwrites 26 core groups (Normal, Comment, String, Keyword, StatusLine, ...) with colors from `~/.cache/hyde/wall.dcol`.
  With `chadrc` set to `ayu_dark` (bg `#0B0E14`), `Normal` came out as bg `#16292e` (the HyDE `dcol_pry1`), while `St_NormalMode` stayed ayu (`#43b0e6`).
  The picker switches cleanly inside a session, then the next start re-applies the override.
- `lua/wallbash_theme.lua` is untracked in chadvim, and the `init.lua` line is uncommitted.
  Identical copies of both files live in `~/dotfiles/cli/.config/nvim/` (commit `004b312`), and the dotfiles README (lines 34 and 48) documents them as "nvim's wallbash hook".
  The files in `~/.config/nvim` are regular files, not stow symlinks, so `~/dotfiles/install.sh` would hit a stow conflict on the `cli` package.
- Also uncommitted: `lazy-lock.json` (plugin updates) and `chadrc.lua` (`default-dark` changed to `ayu_dark` by the picker today).
- base46 loads user themes with `pcall(require, "themes." .. name)` (`base46/init.lua:50`), so a theme at `lua/themes/<name>.lua` is supported.
- base46 ships integrations for blink, telescope, nvimtree, trouble, todo, gitsigns, diffview and others, but none for snacks, oil, mini.diff or codediff.
- Agent-reload handling already exists: `lua/autocmds.lua:54-87` runs `checktime` on FocusGained, BufEnter, TermLeave and TermClose.
- herdr 0.7.5 is installed. `~/.config/herdr/config.toml` holds only `onboarding = false`. The directory also holds runtime files (`herdr.sock`, logs, `session.json`).
- CLI tools present: lazygit, ripgrep, tree-sitter, node, npm, a C compiler, fd 10.5.0, git-delta 0.20.1.
- The repo has no `AGENTS.md`, `docs/STATE.md` or `docs/DECISIONS.md` yet. It has `docs/CODE-TOUR.md` and `docs/CONCEPTS.md`.

## Decisions

Marked "owner" when the owner decided it in conversation, "builder call" when Claude decided it and the owner can veto.

### Plugin swaps (owner: for a duplicated job, devaslife's tool wins)

| Job | Remove | Add | Knock-on work |
|---|---|---|---|
| Completion | nvim-cmp, LuaSnip, friendly-snippets, cmp_luasnip, cmp-nvim-lsp, cmp-nvim-lua, cmp-buffer, cmp-async-path | blink.cmp (v1) | Rewire completion sources for lazydev, vim-dadbod-completion and crates.nvim (`lua/plugins/lang.lua:14` sets `completion.cmp`). base46 has a blink integration, add it to `chadrc` integrations. |
| Picker | telescope.nvim, telescope-ui-select.nvim | snacks.nvim picker | Remap every Telescope command: `lua/mappings.lua:27,53-61`, `lua/configs/lspconfig.lua:16-19,27-28`, `lua/plugins/editor.lua:83-84` (TodoTelescope), octo `picker = "telescope"` at `lua/plugins/git.lua:60`, plus NvChad's own default Telescope maps. `vim.ui.select` goes to snacks. |
| File explorer | nvim-tree.lua | oil.nvim | `lua/mappings.lua:26` `<leader>e`, NvChad's `<C-n>`, `lua/plugins/claude.lua:62` (`ft = "NvimTree"`), the `!NvimTree` exclude in `lua/plugins/ui.lua:13`. |
| Auto pairs | nvim-autopairs | mini.pairs | Cheatsheet exclude at `lua/configs/cheatsheet.lua:243`. |
| Diff review | diffview.nvim | codediff.nvim, mini.diff (`craftzdog/mini.diff`, branch `feat/grouping`) | `lua/plugins/git.lua:37-42` keys `<leader>gd`, `<leader>gf`, `<leader>gF` move to codediff equivalents. mini.diff overlay gets a toggle key and `]c`/`[c` hunk jumps that do not fight gitsigns. Drop `diffview` from base46 integrations. |
| Color codes | nvim-colorizer.lua | nvim-highlight-colors | Cheatsheet entries at `lua/configs/cheatsheet.lua:225-226`. |

NvChad bundles some of the removed plugins (nvim-cmp, telescope, nvim-tree, nvim-autopairs, LuaSnip).
Disable them through lazy.nvim specs (`enabled = false`) rather than forking NvChad.

### Additions from devaslife (owner)

- snacks.nvim modules: picker, notifier, lazygit (float), words. Not indent, statuscolumn, dashboard or scroll, because NvChad's UI covers those (builder call).
- gitlinker.nvim (copy GitHub links to lines).
- mason-tool-installer.nvim, fed from the existing `M.mason.pkgs` list in `chadrc.lua` so there is one source of truth, with auto-update off (builder call).
- "Copy path for agents" keymaps: copy `relative/path#L<line>`, copy the absolute path the same way, and copy a visual selection as a fenced code block that carries the filename and line range. Keys picked to fit the owner's leader scheme and to not collide (builder call).
- devaslife's editor behaviors that are not keybindings, where missing today: ignorecase with smartcase, persistent undo, yank highlight, cursorline only in the active window, rounded borders on floats. Not mouse off and not `cmdheight = 0` (builder call: those remove capability or touch NvChad UI).

### Kept as is (owner)

Everything not listed above stays, including: the DAP stack (nvim-dap, dap-ui, dap-virtual-text, dap-python, dap-go, one-small-step-for-vimkind), neotest with its golang, python and vitest adapters, kulala, vim-dadbod with dadbod-ui and dadbod-completion, hex.nvim, compiler-explorer, flash, harpoon, grug-far, persistence, mini.surround, ts-comments, nvim-ts-autotag, rustaceanvim, crates, schemastore, lazydev, octo, nvim-lint, render-markdown, nvim-treesitter-context, trouble, todo-comments, gitsigns, conform, typr, vim-wakatime, claudecode.nvim.
"Kept" still means each one must load without error, be lazy-loaded where possible, and have working keys after the swaps.

### Restart (owner, informed)

Neovim 0.12.5 ships `:restart` and the `ZR` normal-mode command (`:help ZR`).
No mapping is added.
`:restart` saves the session, quits with `:qall`, starts a new Nvim with the same arguments and restores the session.
Restarting kills anything running in a Neovim `:terminal`, which is why the agent lives in herdr.

### Agent layout (owner: follow devaslife)

- herdr is the outer program. One herdr workspace per project. In each workspace, Neovim in one pane and Claude Code in another, side by side.
- Claude Code never runs inside a Neovim `:terminal`.
- claudecode.nvim stays as the bridge (builder call): it runs with no terminal of its own, and Claude Code in the herdr pane attaches with `/ide`, so selections, at-mentions and diff previews still work and survive `ZR`.
- herdr is recommended, not required (builder call).
  When Neovim runs inside herdr (detected from herdr's pane environment variables), claudecode.nvim uses terminal provider `none`, and the terminal keys in `lua/plugins/claude.lua` (`<leader>ac` toggle, `<leader>af` focus, `<leader>ar` resume) are not mapped.
  Outside herdr, the provider falls back to a Neovim terminal and those keys work as today, so public users without herdr still get a working Claude key set.
  The bridge keys (send selection, add file, accept or deny diff) are mapped in both cases. The cheatsheet shows whichever set is active.
- herdr keeps its default keybindings (owner said not devaslife's keys). From devaslife's herdr config, take only non-key settings that fit: `[ui] sidebar_start_collapsed`, `[ui.sidebar.agents.rows_by_agent]` showing Claude's terminal title, `[terminal] new_cwd = "follow"`, and a `[[keys.command]]` that opens lazygit in a pane on a key that does not collide with herdr defaults (builder call).
  Validate with `herdr config check` against the installed 0.7.5. Any setting that does not exist there is reported in the step summary, not dropped silently.

### Git signs and hunks (builder call, following devaslife's dotfiles)

- gitsigns owns the sign column, blame and staging.
- mini.diff owns the overlay (`overlay_style = "hunk"`, his fork) and the `]c` and `[c` hunk jumps, as in his `plugins/editor.lua`. Its own signs stay off so the two never draw in the same column.

### External tools (builder call)

- `fd` and `git-delta` are installed (owner ran pacman on 2026-11-04).
- delta is used as lazygit's diff pager, as devaslife does. The lazygit config goes in `~/dotfiles/cli/.config/lazygit/config.yml`.

### Working rhythm (builder call)

- Three owner checkpoints instead of one per phase: after Phase 1 (theme), after Phases 2 and 3 (swaps and additions), and after Phase 4 (agent workflow). Phases 0, 5 and 6 are checked together with the final review.
- Commits stay local. Pushing `feat/rebuild` and opening a PR happens only when the owner asks.

### Theme (builder call, owner approved the direction)

- Delete the startup override: the `init.lua` line and `lua/wallbash_theme.lua`.
- Add `lua/themes/wallbash.lua`, a real base46 theme.
  It reads `$HYDE_CACHE_HOME/wall.dcol` (default `~/.cache/hyde/wall.dcol`) when required and maps the HyDE palette onto base46's full `base_30` and `base_16` tables.
  When the file is missing (no HyDE), it falls back to base46's `ayu_dark` palette (owner), so the theme never errors.
- `wallbash` is the default theme in the published `chadrc.lua` (owner). On a machine without HyDE that means a fresh clone opens in `ayu_dark` colors.
  It sets `type` (dark or light) from the palette, so light HyDE themes produce a light base46 theme.
- Selecting `wallbash` in the NvChad picker means "follow HyDE". Selecting any other theme means exactly that theme and nothing overrides it.
- Live follow: while the active theme is `wallbash`, watch `wall.dcol` with `vim.uv` file events, and on change recompile and reload base46 highlights, debounced. When the active theme is anything else, do nothing.
- Plugins without a base46 integration (snacks picker and notifier, oil, mini.diff, codediff) get `hl_add` or `hl_override` entries in `chadrc.lua` only where they look wrong, in the same style as the existing LazyButton and TreesitterContext fixes.

### Repository ownership (builder call)

- chadvim (`~/.config/nvim`) owns every file under `~/.config/nvim`.
- In `~/dotfiles`: remove the `cli/.config/nvim` package content, and change README lines 34 and 48 to say Neovim theming lives in chadvim's `wallbash` theme.
- Add `~/dotfiles/terminal/.config/herdr/config.toml` (the `terminal` package already holds tmux).
  `~/.config/herdr` must stay a real directory so stow links only `config.toml`. Otherwise stow folds the whole directory into the repo, and herdr's socket, logs and session file would land in git.
- Work happens on branch `feat/rebuild` in chadvim and on a separate branch in dotfiles. One commit per step, Conventional Commits, no agent attribution anywhere.

## Steps

Each step follows devaslife's loop: Claude implements only that step, checks `nvim --headless +qa` prints nothing, verifies the behavior end to end in a real Neovim inside kitty and herdr (screenshots for anything visual), then commits.
The owner does a hands-on check at the end of each phase.

### Phase 0: Baseline

- 0.1 Create `feat/rebuild`. Commit the pending `lazy-lock.json` update on its own.
- 0.2 Record the baseline: startup time (`--startuptime`, median of 5 runs), `:checkhealth` warnings, and the list of every keymap whose right-hand side calls a command or plugin.

### Phase 1: Theme

- 1.1 Remove the override (`init.lua` line, `lua/wallbash_theme.lua`).
- 1.2 Add `lua/themes/wallbash.lua` with the fallback palette. Confirm the NvChad picker lists it.
- 1.3 Live follow on `wall.dcol` change.
- 1.4 Dotfiles side: remove `cli/.config/nvim`, fix the README.
- Acceptance: pick `ayu_dark`, restart, and every sampled group (Normal, Comment, String, Keyword, StatusLine, St_NormalMode, a telescope or picker group) matches ayu_dark. Pick `wallbash`, change the HyDE theme, and the open Neovim repaints without restart. Rename `wall.dcol` away and `wallbash` still loads. A light HyDE theme gives a readable light theme, including the Lazy button row.

### Phase 2: Swaps

- 2.1 Picker: telescope to snacks, with every remap from the table.
- 2.2 Explorer: nvim-tree to oil.
- 2.3 Completion: nvim-cmp to blink.cmp, including the lazydev, dadbod and crates sources.
- 2.4 Pairs: nvim-autopairs to mini.pairs.
- 2.5 Diff: diffview to codediff and mini.diff.
- 2.6 Colors: nvim-colorizer to nvim-highlight-colors.
- 2.7 Update the cheatsheet (`lua/configs/cheatsheet.lua`) and base46 integrations for all of the above.
- Acceptance per swap: the old plugin is absent from `lazy-lock.json`, the replacement works in a real buffer, and every key that used the old plugin opens the replacement. After 2.7, a script walks all keymaps and confirms none references a missing command or module.

### Phase 3: Additions

- 3.1 snacks notifier, lazygit float and words.
- 3.2 gitlinker.
- 3.3 mason-tool-installer fed from `chadrc` `M.mason.pkgs`.
- 3.4 Copy-path keymaps for agents.
- 3.5 Missing editor behaviors from the list above.
- 3.6 Theme pass: check every new float and picker in `wallbash`, one dark base46 theme and one light base46 theme, and patch highlights in `chadrc` where text is unreadable or backgrounds clash.

### Phase 4: Agent workflow

- 4.1 herdr config in dotfiles and stowed.
- 4.2 claudecode.nvim with no built-in terminal, and Claude Code in a herdr pane attaching with `/ide`.
- 4.3 Verify agent edits reload in the open buffer inside herdr, which depends on herdr passing focus events to the pane. If it does not, fix it.
- 4.4 Verify `ZR` with a herdr layout: Neovim comes back with its windows, and the Claude pane is untouched. Check nvdash does not cover the restored session.

### Phase 5: Clean-up and kept plugins

- 5.1 Every kept plugin loads and its keys work, lazy-loaded on `cmd`, `ft`, `keys` or `event` where possible.
- 5.2 File layout: group `lua/plugins/` by job, remove dead code and stale comments.
- 5.3 Startup time is no worse than the Phase 0 baseline.

### Phase 6: Docs for publishing

- 6.1 `AGENTS.md` (with `CLAUDE.md` as a symlink), `docs/STATE.md`, `docs/DECISIONS.md`, following the owner's global rules.
- 6.2 Rewrite `README.md` for public users: what it is, screenshots, install, the herdr layout, the theme behavior, required tools (including `fd` and `git-delta`), and credit to devaslife with a link to his dotfiles. Do not copy his config text verbatim.

## Edge cases and risks

- `craftzdog/mini.diff` `feat/grouping` is a personal fork branch. Pin it in `lazy-lock.json`, and note in DECISIONS that upstream `nvim-mini/mini.diff` is the fallback.
- herdr is pre-1.0 and its config keys change between releases. Record the herdr version the config was written against.
- Key collisions across layers: Hyprland, kitty, herdr, Neovim. The herdr prefix and any herdr `ctrl+shift` binds must not shadow Neovim keys the owner uses. Check before committing 4.1.
- NvChad's theme picker writes the chosen theme into `chadrc.lua`, so every theme change shows up as a git diff. This is NvChad behavior and is left alone.
- Several Neovim instances means several claudecode.nvim lock files. `/ide` must attach to the instance in the same workspace.
- Several agents editing one repo at once conflict. Recommended practice (documented in the README, not enforced): one git worktree per agent, one herdr workspace per worktree.
- `:restart` session restore and `persistence.nvim` both deal with sessions. Make sure they do not fight.
- blink.cmp v1 downloads a prebuilt fuzzy matcher binary on first install. The network is slow, so the first launch after 2.3 may take a while. A Rust fallback exists.

## Left to the builder

- Exact snacks picker options, oil options (float or split, columns), blink keymaps and sources order, codediff and mini.diff options.
- Keys for new features (copy path, mini.diff toggle, gitlinker, lazygit float), within the owner's existing leader scheme and with no collisions.
- The exact mapping from HyDE `dcol_*` colors to base46 `base_30` and `base_16` slots, as long as contrast stays readable in both dark and light palettes.
- How E2E checks are driven (kitty remote control, grim screenshots, herdr CLI).
- File layout inside `lua/`.

## Open questions

None.
